import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/question.dart';

class QuestionService {
  static const String _generalQuestionsPath = 'assets/general_questions.json';
  static const String _religiousQuestionsPath = 'assets/religious_questions.json';
  static const String _sportsQuestionsPath = 'assets/sports_questions.json';
  static const String _historyGeographyQuestionsPath = 'assets/history_geography_questions.json';
  static const String _intelligenceLogicQuestionsPath = 'assets/intelligence_questions.json';
  static const String _civilizationsAntiquitiesQuestionsPath = 'assets/civilizations_antiquities_questions.json';

  static Future<List<Question>> loadQuestions() async {
    try {
      // Load all questions from separate files
      final List<Question> allQuestions = [];
      
      // Load general questions
      final generalQuestions = await _loadQuestionsFromFile(_generalQuestionsPath);
      allQuestions.addAll(generalQuestions);
      
      // Load religious questions
      final religiousQuestions = await _loadQuestionsFromFile(_religiousQuestionsPath);
      allQuestions.addAll(religiousQuestions);
      
      // Load sports questions
      final sportsQuestions = await _loadQuestionsFromFile(_sportsQuestionsPath);
      allQuestions.addAll(sportsQuestions);
      
      // Load history/geography questions
      final historyGeographyQuestions = await _loadQuestionsFromFile(_historyGeographyQuestionsPath);
      allQuestions.addAll(historyGeographyQuestions);
      
      // Load intelligence/logic questions
      final intelligenceLogicQuestions = await _loadQuestionsFromFile(_intelligenceLogicQuestionsPath);
      allQuestions.addAll(intelligenceLogicQuestions);
      
      // Load civilizations/antiquities questions
      final civilizationsAntiquitiesQuestions = await _loadQuestionsFromFile(_civilizationsAntiquitiesQuestionsPath);
      allQuestions.addAll(civilizationsAntiquitiesQuestions);
      
      // Shuffle questions randomly
      return _shuffleQuestions(allQuestions);
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  static Future<List<Question>> loadQuestionsByCategory(String category) async {
    try {
      String filePath;
      
      switch (category) {
        case 'general':
          filePath = _generalQuestionsPath;
          break;
        case 'religious':
          filePath = _religiousQuestionsPath;
          break;
        case 'sports':
          filePath = _sportsQuestionsPath;
          break;
        case 'historyGeography':
        case 'history_geography':
          filePath = _historyGeographyQuestionsPath;
          break;
        case 'intelligenceLogic':
        case 'intelligence_logic':
          filePath = _intelligenceLogicQuestionsPath;
          break;
        case 'civilizationsAntiquities':
        case 'civilizations_antiquities':
          filePath = _civilizationsAntiquitiesQuestionsPath;
          break;
        default:
          throw Exception('Unknown category: $category');
      }
      
      final questions = await _loadQuestionsFromFile(filePath);
      // Shuffle questions randomly for this category
      return _shuffleQuestions(questions);
    } catch (e) {
      throw Exception('Failed to load questions for category $category: $e');
    }
  }

  static Future<List<Question>> _loadQuestionsFromFile(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> questionsJson = jsonData['questions'];
      return questionsJson
          .map((json) => Question.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load questions from $path: $e');
    }
  }

  static List<Question> _shuffleQuestions(List<Question> questions) {
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

  static Map<int, int> generateAudiencePoll(Question question) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final correctAnswer = question.correctAnswer;
    
    // Generate percentages with bias towards correct answer
    final percentages = <int, int>{};
    const totalPercentage = 100;
    
    // Give correct answer 40-60% chance
    final correctPercentage = 40 + (random % 21);
    percentages[correctAnswer] = correctPercentage;
    
    // Distribute remaining percentage among other answers
    int remaining = totalPercentage - correctPercentage;
    for (int i = 0; i < 4; i++) {
      if (i != correctAnswer) {
        if (i == 3 || (correctAnswer == 3 && i == 2)) {
          percentages[i] = remaining;
        } else {
          final portion = (remaining / (4 - (correctAnswer == 3 ? 1 : 2))).round();
          percentages[i] = portion;
          remaining -= portion;
        }
      }
    }
    
    return percentages;
  }

  static List<int> getFiftyFiftyRemovals(Question question) {
    final correctAnswer = question.correctAnswer;
    final removals = <int>[];
    
    // Remove 2 wrong answers
    for (int i = 0; i < 4; i++) {
      if (i != correctAnswer && removals.length < 2) {
        removals.add(i);
      }
    }
    
    return removals;
  }
}
