class QuestionModel {
  final String id;
  final String questionText;
  final Map<String, String> options;
  final String correctOption;
  final String category;
  final String difficulty;
  final String language;

  const QuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOption,
    required this.category,
    this.difficulty = 'medium',
    this.language = 'en',
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    Map<String, String> opts;
    if (json['options'] is Map) {
      final raw = json['options'] as Map;
      opts = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else {
      opts = {
        'A': json['option_a']?.toString() ?? '',
        'B': json['option_b']?.toString() ?? '',
        'C': json['option_c']?.toString() ?? '',
        'D': json['option_d']?.toString() ?? '',
      };
    }
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      questionText:
          json['question_text']?.toString() ?? json['question']?.toString() ?? '',
      options: opts,
      correctOption: json['correct_option']?.toString() ??
          json['correct']?.toString() ??
          'A',
      category: json['category']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      language: json['language']?.toString() ?? 'en',
    );
  }
}
