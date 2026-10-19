class Assessment {
  final int? id;
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
    this.id,
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

  factory Assessment.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final material = json['readingMaterial'] as Map<String, dynamic>?;
    final accuracyDetails = json['accuracyDetails'] as Map<String, dynamic>?;

    final finalAccuracy = (json['accuracy'] as num).toDouble();
    final initialAccuracy = accuracyDetails != null &&
            accuracyDetails['initialAccuracy'] != null
        ? (accuracyDetails['initialAccuracy'] as num).toDouble()
        : finalAccuracy;
    final isVerified = accuracyDetails != null &&
            accuracyDetails['isVerified'] != null
        ? accuracyDetails['isVerified'] as bool
        : false;

    return Assessment(
      id: json['id'] as int?,
      studentName: student?['fullName']?.toString() ??
          json['studentName']?.toString() ??
          'Unknown Student',
      materialTitle: material?['title']?.toString() ??
          json['materialTitle']?.toString() ??
          'Unknown Material',
      passage: material?['passage']?.toString() ??
          json['passage']?.toString() ??
          '',
      date: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
      initialAccuracy: initialAccuracy,
      accuracy: finalAccuracy,
      wpm: (json['wpm'] as num).toDouble(),
      comprehension: (json['comprehensionScore'] as num).toDouble(),
      classification: json['classification']?.toString() ?? '',
      isVerified: isVerified,
    );
  }
}