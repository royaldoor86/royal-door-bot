
enum QuestionCategory {
  general,
  religious,
  sports,
  historyGeography,
  intelligenceLogic,
  civilizationsAntiquities,
}

class Question {
  final int id;
  final String question;
  final List<String> answers;
  final int correctAnswer;
  final int difficulty;
  final int prize;
  final QuestionCategory category;

  Question({
    required this.id,
    required this.question,
    required this.answers,
    required this.correctAnswer,
    required this.difficulty,
    required this.prize,
    required this.category,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      answers: List<String>.from(json['answers']),
      correctAnswer: json['correctAnswer'],
      difficulty: json['difficulty'],
      prize: json['prize'],
      category: _parseCategory(json['category']),
    );
  }

  static QuestionCategory _parseCategory(String category) {
    switch (category) {
      case 'general':
        return QuestionCategory.general;
      case 'religious':
        return QuestionCategory.religious;
      case 'sports':
        return QuestionCategory.sports;
      case 'historyGeography':
      case 'history_geography':
        return QuestionCategory.historyGeography;
      case 'intelligenceLogic':
      case 'intelligence_logic':
        return QuestionCategory.intelligenceLogic;
      case 'civilizationsAntiquities':
      case 'civilizations_antiquities':
        return QuestionCategory.civilizationsAntiquities;
      default:
        return QuestionCategory.general;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answers': answers,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
      'prize': prize,
      'category': category.name,
    };
  }
}
