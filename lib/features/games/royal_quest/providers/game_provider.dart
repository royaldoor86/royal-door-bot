import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/sound_service.dart';
import '../services/game_wallet_service.dart';
import '../services/anti_cheat_service.dart';

class GameProvider with ChangeNotifier {
  GameState _state = GameState(
    questions: [],
    status: GameStatus.idle,
  );

  Timer? _timer;
  Timer? _answerDelayTimer;

  GameState get state => _state;
  bool get mounted => _mounted;

  final GameWalletService _walletService = GameWalletService();
  final AntiCheatService _antiCheatService = AntiCheatService();
  String? _currentSessionId;
  bool _mounted = true;

  GameProvider() {
    // Initialize with zero values first
    _state = _state.copyWith(
      playerBalance: PlayerBalance(gems: 0, coins: 0),
    );
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      final questions = await QuestionService.loadQuestions();
      // Get real wallet balance
      final gems = await _walletService.getGemsBalance();
      final coins = await _walletService.getCoinsBalance();
      
      debugPrint('Loaded wallet balance: gems=$gems, coins=$coins');
      
      _state = _state.copyWith(
        questions: questions,
        allQuestions: questions,
        playerBalance: PlayerBalance(gems: gems, coins: coins),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing game: $e');
      // Set zero values on error - user must have balance to play
      _state = _state.copyWith(
        questions: [],
        allQuestions: [],
        playerBalance: PlayerBalance(gems: 0, coins: 0),
      );
      notifyListeners();
    }
  }

  void selectCurrency(CurrencyType currency) {
    _state = _state.copyWith(selectedCurrency: currency);
    notifyListeners();
  }

  Future<void> selectCategory(QuestionCategory category) async {
    if (_state.selectedCurrency == null) return;
    if (!_state.canAffordEntry) return;

    // Anti-cheat: Check for concurrent sessions
    final hasConcurrent = await _antiCheatService.hasConcurrentSession();
    if (hasConcurrent) {
      await _antiCheatService.logSuspiciousActivity('Concurrent game session detected');
      debugPrint('⚠️ Concurrent session detected, blocking game start');
      return;
    }

    // Anti-cheat: Check win rate
    final suspiciousWinRate = await _antiCheatService.isWinRateSuspicious();
    if (suspiciousWinRate) {
      await _antiCheatService.logSuspiciousActivity('Suspicious win rate detected');
      debugPrint('⚠️ Suspicious win rate detected, blocking game start');
      return;
    }

    // Always filter from allQuestions to ensure we have access to all categories
    final sourceQuestions = _state.allQuestions.isNotEmpty 
        ? _state.allQuestions 
        : _state.questions;
    
    debugPrint('Total questions available: ${sourceQuestions.length}');
    debugPrint('Looking for category: $category');
    
    final filteredQuestions = sourceQuestions.where((q) => q.category == category).toList();
    
    debugPrint('Found ${filteredQuestions.length} questions for category $category');
    
    if (filteredQuestions.isEmpty) {
      debugPrint('No questions found for category: $category');
      debugPrint('Available categories in questions: ${sourceQuestions.map((q) => q.category).toSet()}');
      return;
    }

    // Shuffle questions randomly for this game session
    final shuffledQuestions = _shuffleQuestions(filteredQuestions);

    // Create anti-cheat session
    try {
      _currentSessionId = await _antiCheatService.createGameSession();
      debugPrint('Game session created: $_currentSessionId');
    } catch (e) {
      debugPrint('Failed to create game session: $e');
      return;
    }

    // Deduct entry fee
    final newBalance = await _deductEntryFee();
    
    // Calculate initial stage reward (only if not already set)
    final stageReward = _state.currentStageReward > 0 
        ? _state.currentStageReward 
        : (_state.selectedCurrency == CurrencyType.gems 
            ? GameState.stageRewardGems 
            : GameState.stageRewardCoins);
    
    _state = _state.copyWith(
      selectedCategory: category,
      questions: shuffledQuestions,
      playerBalance: newBalance,
      status: GameStatus.playing,
      currentQuestionInStage: 1,
      currentWinnings: 0,
      fiftyFiftyUsed: false,
      changeQuestionUsed: false,
      removedAnswers: [],
      remainingTime: GameState.questionTime,
      totalQuestionsAnswered: 0,
      showingAnswerResult: false,
      resetAnswerState: true,
      currentQuestionIndex: 0,
      currentStageReward: stageReward,
    );
    
    _startTimer();
    notifyListeners();
  }

  List<Question> _shuffleQuestions(List<Question> questions) {
    // Fisher-Yates shuffle algorithm for true randomness
    final random = Random();
    final List<Question> shuffled = List.from(questions);
    
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    
    return shuffled;
  }

  Future<PlayerBalance> _deductEntryFee() async {
    bool success;
    if (_state.selectedCurrency == CurrencyType.gems) {
      success = await _walletService.deductGems(GameState.entryFeeGems);
      if (success) {
        return _state.playerBalance.copyWith(
          gems: _state.playerBalance.gems - GameState.entryFeeGems,
        );
      }
    } else {
      success = await _walletService.deductCoins(GameState.entryFeeCoins);
      if (success) {
        return _state.playerBalance.copyWith(
          coins: _state.playerBalance.coins - GameState.entryFeeCoins,
        );
      }
    }
    return _state.playerBalance;
  }

  void _startTimer() {
    _timer?.cancel();
    _state = _state.copyWith(remainingTime: GameState.questionTime);
    SoundService.playTimerSound(); // Play timer sound when question starts
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_state.remainingTime > 0) {
        _state = _state.copyWith(remainingTime: _state.remainingTime - 1);
        notifyListeners();
      } else {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    _timer?.cancel();
    _answerDelayTimer?.cancel();
    SoundService.stopTimerSound(); // Stop timer sound
    _state = _state.copyWith(
      selectedAnswer: null,
      isAnswerCorrect: null,
      showingAnswerResult: false,
    );
    notifyListeners();
    _endGame(false);
  }

  void selectAnswer(int answerIndex) {
    if (_state.status != GameStatus.playing) return;
    if (_state.selectedAnswer != null || _state.showingAnswerResult || _state.isAnswerSelected) return;

    // Anti-cheat: Check answer speed
    if (_antiCheatService.isAnsweringTooFast()) {
      _antiCheatService.logSuspiciousActivity('Answering too fast');
      if (_currentSessionId != null) {
        _antiCheatService.invalidateSession(_currentSessionId!, 'Answering too fast');
      }
      _endGame(false);
      return;
    }

    _timer?.cancel();
    SoundService.stopTimerSound(); // Stop timer sound when answer is selected

    final currentQuestion = _state.currentQuestion;
    final isCorrect = answerIndex == currentQuestion.correctAnswer;

    // Anti-cheat: Record answer in session
    if (_currentSessionId != null) {
      _antiCheatService.recordAnswer(
        _currentSessionId!,
        currentQuestion.id,
        answerIndex,
        isCorrect,
      );
    }

    // Step 1: Show yellow selection (user just selected)
    _state = _state.copyWith(
      selectedAnswer: answerIndex,
      isAnswerSelected: true,
    );
    notifyListeners();

    // Step 2: After 1.5 seconds, show result colors
    _answerDelayTimer?.cancel();
    _answerDelayTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) {
        _answerDelayTimer?.cancel();
        return;
      }

      // Play sound based on answer
      if (isCorrect) {
        SoundService.playCorrectAnswerSound();
      } else {
        SoundService.playWrongAnswerSound();
      }

      _state = _state.copyWith(
        isAnswerCorrect: isCorrect,
        showingAnswerResult: true,
      );
      notifyListeners();

      // Step 3: After 2 more seconds, proceed
      _answerDelayTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) {
          _answerDelayTimer?.cancel();
          return;
        }
        _state = _state.copyWith(showingAnswerResult: false);
        notifyListeners();

        if (isCorrect) {
          _handleCorrectAnswer();
        } else {
          _endGame(false);
        }
      });
    });
  }

  void _handleCorrectAnswer() {
    _answerDelayTimer?.cancel();
    
    // Add partial reward per correct answer (total stage reward / 10)
    final rewardPerQuestion = _state.currentStageReward ~/ GameState.questionsPerStage;
    final newWinnings = _state.currentWinnings + rewardPerQuestion;
    final newQuestionInStage = _state.currentQuestionInStage + 1;
    final totalAnswered = _state.totalQuestionsAnswered + 1;
    final newQuestionIndex = _state.currentQuestionIndex + 1;

    if (newQuestionInStage > GameState.questionsPerStage) {
      _completeStage(newWinnings, totalAnswered);
    } else {
      _state = _state.copyWith(
        currentQuestionInStage: newQuestionInStage,
        currentWinnings: newWinnings,
        removedAnswers: [],
        remainingTime: GameState.questionTime,
        totalQuestionsAnswered: totalAnswered,
        showingAnswerResult: false,
        resetAnswerState: true,
        currentQuestionIndex: newQuestionIndex,
      );
      _startTimer();
    }
    notifyListeners();
  }

  void _completeStage(int winnings, int totalAnswered) {
    _state = _state.copyWith(
      currentWinnings: winnings,
      totalQuestionsAnswered: totalAnswered,
      status: GameStatus.stageComplete,
    );
    _timer?.cancel();
    notifyListeners();
  }

  Future<void> _endGame(bool won) async {
    _timer?.cancel();
    _answerDelayTimer?.cancel();
    
    // Anti-cheat: Validate session before processing win
    if (_currentSessionId != null) {
      final isValid = await _antiCheatService.validateGameSession(_currentSessionId!);
      if (!isValid && won) {
        debugPrint('⚠️ Invalid session detected, blocking win');
        await _antiCheatService.logSuspiciousActivity('Invalid session on win attempt');
        _state = _state.copyWith(
          status: GameStatus.gameOver,
          currentWinnings: 0,
        );
        notifyListeners();
        return;
      }
    }
    
    if (won) {
      // Add winnings to balance when winning
      final newBalance = await _addWinningsToBalance();
      _state = _state.copyWith(
        status: GameStatus.winner,
        playerBalance: newBalance,
        currentWinnings: 0,
      );
    } else {
      // On loss: reset winnings to 0 but keep original balance
      // Don't reset the actual wallet balance in Firestore
      _state = _state.copyWith(
        status: GameStatus.gameOver,
        currentWinnings: 0,
      );
    }
    
    // Reset session
    _currentSessionId = null;
    notifyListeners();
  }

  Future<void> endGameWithLoss() async {
    _timer?.cancel();
    _answerDelayTimer?.cancel();
    // Don't reset the actual wallet balance in Firestore
    // Just reset the game state
    
    _state = _state.copyWith(
      status: GameStatus.gameOver,
      currentWinnings: 0,
    );
    notifyListeners();
  }

  Future<void> useFiftyFifty() async {
    if (_state.fiftyFiftyUsed || !_state.canAffordLifeline) return;

    final question = _state.currentQuestion;
    final correctAnswer = question.correctAnswer;
    
    final wrongAnswers = [0, 1, 2, 3].where((i) => i != correctAnswer).toList();
    wrongAnswers.shuffle();
    final toRemove = wrongAnswers.take(2).toList();
    
    final newBalance = await _deductLifelineCost();
    
    _state = _state.copyWith(
      removedAnswers: toRemove,
      fiftyFiftyUsed: true,
      playerBalance: newBalance,
    );
    notifyListeners();
  }

  Future<void> useChangeQuestion() async {
    if (_state.changeQuestionUsed || !_state.canAffordLifeline) return;

    final newBalance = await _deductLifelineCost();

    // Get current question index and replace with a different question from the same category
    final currentQuestionIndex = _state.currentQuestionIndex;
    final category = _state.selectedCategory;

    // Filter questions by category and exclude current question
    final availableQuestions = _state.questions.where((q) =>
      q.category == category && _state.questions.indexOf(q) != currentQuestionIndex
    ).toList();

    if (availableQuestions.isEmpty) {
      debugPrint('No alternative questions available');
      return;
    }

    // Shuffle available questions using Fisher-Yates algorithm for true randomness
    final shuffledQuestions = _shuffleQuestions(availableQuestions);
    final newQuestion = shuffledQuestions.first;

    // Replace the question at the current index with the new question
    final updatedQuestions = List<Question>.from(_state.questions);
    updatedQuestions[currentQuestionIndex] = newQuestion;

    _timer?.cancel();
    _answerDelayTimer?.cancel();
    SoundService.stopTimerSound();

    _state = _state.copyWith(
      changeQuestionUsed: true,
      playerBalance: newBalance,
      questions: updatedQuestions,
      removedAnswers: [],
      remainingTime: GameState.questionTime,
      resetAnswerState: true,
    );
    _startTimer();
    notifyListeners();
  }

  Future<PlayerBalance> _deductLifelineCost() async {
    bool success;
    if (_state.selectedCurrency == CurrencyType.gems) {
      success = await _walletService.deductGems(GameState.lifelineCost);
      if (success) {
        return _state.playerBalance.copyWith(
          gems: _state.playerBalance.gems - GameState.lifelineCost,
        );
      }
    } else {
      success = await _walletService.deductCoins(GameState.lifelineCost);
      if (success) {
        return _state.playerBalance.copyWith(
          coins: _state.playerBalance.coins - GameState.lifelineCost,
        );
      }
    }
    return _state.playerBalance;
  }

  Future<void> withdrawWinnings() async {
    final newBalance = await _addWinningsToBalance();
    
    _state = _state.copyWith(
      playerBalance: newBalance,
      status: GameStatus.idle,
      selectedCurrency: null,
      selectedCategory: null,
      currentWinnings: 0,
    );
    notifyListeners();
  }

  void continueToNextStage() {
    SoundService.playNextLevelSound();
    
    // Increase stage reward for subsequent stages
    final newStageReward = _state.currentStageReward * 2;
    
    _state = _state.copyWith(
      status: GameStatus.idle,
      currentStage: _state.currentStage + 1,
      currentQuestionInStage: 1,
      currentStageReward: newStageReward,
      fiftyFiftyUsed: false,
      changeQuestionUsed: false,
      removedAnswers: [],
      remainingTime: GameState.questionTime,
      resetAnswerState: true,
      selectedCategory: null, // Reset category to force re-selection
      questions: _state.allQuestions, // Reset questions to all original questions
      // Keep selectedCurrency to allow continuing with same currency
    );
    notifyListeners();
  }

  Future<PlayerBalance> _addWinningsToBalance() async {
    bool success;
    if (_state.selectedCurrency == CurrencyType.gems) {
      success = await _walletService.addGems(_state.currentWinnings);
      if (success) {
        return _state.playerBalance.copyWith(
          gems: _state.playerBalance.gems + _state.currentWinnings,
        );
      }
    } else {
      success = await _walletService.addCoins(_state.currentWinnings);
      if (success) {
        return _state.playerBalance.copyWith(
          coins: _state.playerBalance.coins + _state.currentWinnings,
        );
      }
    }
    return _state.playerBalance;
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resetGame() {
    _stopTimer();
    _answerDelayTimer?.cancel();
    
    // Create a completely new GameState with all fields reset
    _state = GameState(
      questions: _state.allQuestions.isNotEmpty ? _state.allQuestions : _state.questions,
      allQuestions: _state.allQuestions.isNotEmpty ? _state.allQuestions : _state.questions,
      status: GameStatus.idle,
      playerBalance: _state.playerBalance, // Keep the balance
      selectedCurrency: null,
      selectedCategory: null,
      currentStage: 1,
      currentQuestionInStage: 1,
      currentWinnings: 0,
      selectedAnswer: null,
      isAnswerCorrect: null,
      fiftyFiftyUsed: false,
      changeQuestionUsed: false,
      removedAnswers: [],
      remainingTime: GameState.questionTime,
      totalQuestionsAnswered: 0,
      showingAnswerResult: false,
      currentQuestionIndex: 0,
      currentStageReward: 0,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _mounted = false;
    _stopTimer();
    _answerDelayTimer?.cancel();
    SoundService.stopAll();
    super.dispose();
  }
}
