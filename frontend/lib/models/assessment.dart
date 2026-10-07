class Assessment {
  final String studentName;
  final String materialTitle;
  final DateTime date;
  final double accuracy;
  final double wpm;
  final double comprehension;
  final String classification;

  Assessment({
    required this.studentName,
    required this.materialTitle,
    required this.date,
    required this.accuracy,
    required this.wpm,
    required this.comprehension,
    required this.classification,
  });
}