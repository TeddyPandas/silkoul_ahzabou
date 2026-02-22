class Quiz {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String difficulty;
  final String? imageUrl;

  Quiz({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.difficulty,
    this.imageUrl,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      imageUrl: json['image_url'],
    );
  }
}

class Question {
  final String id;
  final String text;
  final String? explanation;
  final List<Answer> answers;

  Question({
    required this.id,
    required this.text,
    this.explanation,
    required this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['question_text'],
      explanation: json['explanation'],
      answers: (json['answers'] as List<dynamic>?)
              ?.map((a) => Answer.fromJson(a))
              .toList() ??
          [],
    );
  }
}

class Answer {
  final String id;
  final String text;
  final bool isCorrect;

  Answer({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      text: json['text'],
      isCorrect: json['is_correct'] ?? false,
    );
  }
}
