import 'question.dart';

enum CurrencyType {
  gems,
  coins,
}

enum GameStatus {
  idle,
  selectingCategory,
  playing,
  stageComplete,
  paused,
  gameOver,
  winner,
}

enum LifelineType {
  fiftyFifty,
  changeQuestion,
}

class PlayerBalance {
  final int gems;
  final int coins;

  PlayerBalance({
    this.gems = 1000,
    this.coins = 2500,
  });

  PlayerBalance copyWith({
    int? gems,
    int? coins,
  }) {
    return PlayerBalance(
      gems: gems ?? this.gems,
      coins: coins ?? this.coins,
    );
  }
}

class GameState {
  final GameStatus status;
  final PlayerBalance playerBalance;
  final CurrencyType? selectedCurrency;
  final QuestionCategory? selectedCategory;
  final int currentStage;
  final int currentQuestionInStage;
  final int currentWinnings;
  final int? selectedAnswer;
  final bool? isAnswerCorrect;
  final bool isAnswerSelected;
  final bool fiftyFiftyUsed;
  final bool changeQuestionUsed;
  final List<int> removedAnswers;
  final int remainingTime;
  final List<Question> questions;
  final List<Question> allQuestions; // Store all original questions
  final int totalQuestionsAnswered;
  final bool showingAnswerResult;
  final int currentQuestionIndex;
  final int currentStageReward;

  static const int questionsPerStage = 10;
  static const int totalStages = 100;
  static const int questionTime = 10;
  static const int lifelineCost = 50;
  static const int stageRewardGems = 200;
  static const int stageRewardCoins = 500;
  static const int entryFeeGems = 100;
  static const int entryFeeCoins = 250;

  GameState({
    this.status = GameStatus.idle,
    PlayerBalance? playerBalance,
    this.selectedCurrency,
    this.selectedCategory,
    this.currentStage = 1,
    this.currentQuestionInStage = 1,
    this.currentWinnings = 0,
    this.selectedAnswer,
    this.isAnswerCorrect,
    this.isAnswerSelected = false,
    this.fiftyFiftyUsed = false,
    this.changeQuestionUsed = false,
    this.removedAnswers = const [],
    this.remainingTime = questionTime,
    required this.questions,
    this.allQuestions = const [],
    this.totalQuestionsAnswered = 0,
    this.showingAnswerResult = false,
    this.currentQuestionIndex = 0,
    this.currentStageReward = 0,
  }) : playerBalance = playerBalance ?? PlayerBalance();

  GameState copyWith({
    GameStatus? status,
    PlayerBalance? playerBalance,
    CurrencyType? selectedCurrency,
    QuestionCategory? selectedCategory,
    int? currentStage,
    int? currentQuestionInStage,
    int? currentWinnings,
    int? selectedAnswer,
    bool? isAnswerCorrect,
    bool? isAnswerSelected,
    bool? fiftyFiftyUsed,
    bool? changeQuestionUsed,
    List<int>? removedAnswers,
    int? remainingTime,
    List<Question>? questions,
    List<Question>? allQuestions,
    int? totalQuestionsAnswered,
    bool? showingAnswerResult,
    bool resetAnswerState = false,
    int? currentQuestionIndex,
    int? currentStageReward,
  }) {
    return GameState(
      status: status ?? this.status,
      playerBalance: playerBalance ?? this.playerBalance,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currentStage: currentStage ?? this.currentStage,
      currentQuestionInStage: currentQuestionInStage ?? this.currentQuestionInStage,
      currentWinnings: currentWinnings ?? this.currentWinnings,
      selectedAnswer: resetAnswerState ? null : (selectedAnswer ?? this.selectedAnswer),
      isAnswerCorrect: resetAnswerState ? null : (isAnswerCorrect ?? this.isAnswerCorrect),
      isAnswerSelected: resetAnswerState ? false : (isAnswerSelected ?? this.isAnswerSelected),
      fiftyFiftyUsed: fiftyFiftyUsed ?? this.fiftyFiftyUsed,
      changeQuestionUsed: changeQuestionUsed ?? this.changeQuestionUsed,
      removedAnswers: resetAnswerState ? const [] : (removedAnswers ?? this.removedAnswers),
      remainingTime: remainingTime ?? this.remainingTime,
      questions: questions ?? this.questions,
      allQuestions: allQuestions ?? this.allQuestions,
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      showingAnswerResult: resetAnswerState ? false : (showingAnswerResult ?? this.showingAnswerResult),
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      currentStageReward: currentStageReward ?? this.currentStageReward,
    );
  }

  Question get currentQuestion {
    if (questions.isNotEmpty && currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    throw Exception('No questions available');
  }

  bool get hasLifelinesAvailable {
    return !fiftyFiftyUsed || !changeQuestionUsed;
  }

  bool get canAffordLifeline {
    if (selectedCurrency == CurrencyType.gems) {
      return playerBalance.gems >= lifelineCost;
    } else {
      return playerBalance.coins >= lifelineCost;
    }
  }

  bool get canAffordEntry {
    if (selectedCurrency == CurrencyType.gems) {
      return playerBalance.gems >= entryFeeGems;
    } else {
      return playerBalance.coins >= entryFeeCoins;
    }
  }

  int get entryFee {
    if (selectedCurrency == CurrencyType.gems) {
      return entryFeeGems;
    } else {
      return entryFeeCoins;
    }
  }
}
