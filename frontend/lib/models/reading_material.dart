class ComprehensionQuestionItem {
  final int? id;
  final int questionOrder;
  final String questionText;
  final String choiceA;
  final String choiceB;
  final String choiceC;
  final String choiceD;
  final String correctAnswer;

  ComprehensionQuestionItem({
    this.id,
    required this.questionOrder,
    required this.questionText,
    required this.choiceA,
    required this.choiceB,
    required this.choiceC,
    required this.choiceD,
    required this.correctAnswer,
  });

  List<String> get choices => [choiceA, choiceB, choiceC, choiceD];

  factory ComprehensionQuestionItem.fromJson(Map<String, dynamic> json) {
    return ComprehensionQuestionItem(
      id: json['id'] as int?,
      questionOrder: json['questionOrder'] as int? ?? 1,
      questionText: json['questionText'] as String,
      choiceA: json['choiceA'] as String,
      choiceB: json['choiceB'] as String,
      choiceC: json['choiceC'] as String,
      choiceD: json['choiceD'] as String,
      correctAnswer: json['correctAnswer'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionOrder': questionOrder,
        'questionText': questionText,
        'choiceA': choiceA,
        'choiceB': choiceB,
        'choiceC': choiceC,
        'choiceD': choiceD,
        'correctAnswer': correctAnswer,
      };
}

class ReadingMaterialItem {
  final int id;
  final String title;
  final String passage;
  final int? gradeLevel;
  final String materialType;
  final int? teacherId;
  final List<ComprehensionQuestionItem> questions;

  ReadingMaterialItem({
    required this.id,
    required this.title,
    required this.passage,
    this.gradeLevel,
    required this.materialType,
    this.teacherId,
    required this.questions,
  });

  bool get isBuiltIn => materialType == 'BUILT_IN';

  factory ReadingMaterialItem.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return ReadingMaterialItem(
      id: json['id'] as int,
      title: json['title'] as String,
      passage: json['passage'] as String,
      gradeLevel: json['gradeLevel'] as int?,
      materialType: json['materialType'] as String? ?? 'BUILT_IN',
      teacherId: json['teacherId'] as int?,
      questions: rawQuestions
          .map((q) =>
              ComprehensionQuestionItem.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}