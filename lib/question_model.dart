class Question {
  final String questionText;
  final String category;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.questionText,
    required this.category,
    required this.options,
    required this.correctAnswerIndex,
  });
}