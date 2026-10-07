class Assessment {
  final String studentName;
  final String materialTitle;
  final String passage;
  final DateTime date;

  final double initialAccuracy;
  final double accuracy;
  final double wpm;
  final double comprehension;
  final String classification;

  final bool isVerified;

  Assessment({
    required this.studentName,
    required this.materialTitle,
    required this.passage,
    required this.date,
    required this.initialAccuracy,
    required this.accuracy,
    required this.wpm,
    required this.comprehension,
    required this.classification,
    required this.isVerified,
  });
}