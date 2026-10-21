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

  static String getWordReadingLevel(double wordReadingScore) {
    final rounded = wordReadingScore.round();
    if (rounded >= 97) return 'Independent';
    if (rounded >= 90) return 'Instructional';
    return 'Frustration';
  }

  static String getComprehensionLevel(double comprehensionScore) {
    final rounded = comprehensionScore.round();
    if (rounded >= 80) return 'Independent';
    if (rounded >= 59) return 'Instructional';
    return 'Frustration';
  }

  static String getReadingProfile(
    double wordReadingScore,
    double comprehensionScore,
  ) {
    final wordLevel = getWordReadingLevel(wordReadingScore);
    final compLevel = getComprehensionLevel(comprehensionScore);

    if (wordLevel == 'Independent' && compLevel == 'Independent') {
      return 'Independent';
    }
    if (wordLevel == 'Frustration' || compLevel == 'Frustration') {
      return 'Frustration';
    }
    return 'Instructional';
  }

  static String getProfileExplanation(
    double wordReadingScore,
    double comprehensionScore,
  ) {
    final wordLevel = getWordReadingLevel(wordReadingScore);
    final compLevel = getComprehensionLevel(comprehensionScore);
    final profile = getReadingProfile(wordReadingScore, comprehensionScore);

    String wordReason;
    if (wordLevel == 'Independent') {
      wordReason =
          'Word Reading is Independent ($wordReadingScore% is within 97%-100%)';
    } else if (wordLevel == 'Instructional') {
      wordReason =
          'Word Reading is Instructional ($wordReadingScore% is within 90%-96%)';
    } else {
      wordReason =
          'Word Reading is Frustration ($wordReadingScore% is 89% or below)';
    }

    String compReason;
    if (compLevel == 'Independent') {
      compReason =
          'Comprehension is Independent ($comprehensionScore% is within 80%-100%)';
    } else if (compLevel == 'Instructional') {
      compReason =
          'Comprehension is Instructional ($comprehensionScore% is within 59%-79%)';
    } else {
      compReason =
          'Comprehension is Frustration ($comprehensionScore% is 58% or below)';
    }

    String meaning;
    if (profile == 'Independent') {
      meaning =
          'Because both areas are Independent, the learner can read and '
          'understand this passage on their own without teacher assistance.';
    } else if (profile == 'Instructional') {
      meaning =
          'Based on Phil-IRI guidelines, the learner is at the Instructional '
          'level and can read and learn from this passage with teacher support.';
    } else {
      meaning =
          'Based on Phil-IRI guidelines, when either area is at the Frustration '
          'level, the overall profile is Frustration. This passage is currently '
          'too difficult for the learner and requires reading intervention.';
    }

    return '$wordReason and $compReason. $meaning';
  }

  String get wordReadingLevel => getWordReadingLevel(accuracy);
  String get comprehensionLevel => getComprehensionLevel(comprehension);
  String get readingProfile => getReadingProfile(accuracy, comprehension);
  String get readingProfileExplanation =>
      getProfileExplanation(accuracy, comprehension);

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