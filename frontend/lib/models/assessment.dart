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

    if (profile == 'Independent') {
      return 'The student can read and understand this passage easily and confidently on their own, without needing assistance.';
    } else if (profile == 'Instructional') {
      return 'The student is making good progress. They can read and understand this passage well with a little guidance and support from the teacher.';
    } else {
      if (wordLevel == 'Frustration' && compLevel == 'Frustration') {
        return 'This passage is currently too challenging for the student in both word reading and understanding. Practicing with simpler stories will help them build confidence.';
      } else if (wordLevel == 'Frustration') {
        return 'The student understands the story, but had difficulty reading several words in this passage. They will benefit from practicing word recognition and sounds with easier materials.';
      } else {
        return 'The student was able to read the words, but found it difficult to understand the passage. They will benefit from guided questions and vocabulary support.';
      }
    }
  }

  static String getClassificationExplanation(String classification) {
    switch (classification.toLowerCase().trim()) {
      case 'normal':
        return 'The student has well-balanced reading skills. They read the words accurately, maintain a natural pace, and understand what they read.';
      case 'decoding':
        return 'The student understands the story well, but struggles to recognize or pronounce some words correctly. Practicing phonics and sight words will help.';
      case 'fluency':
        return 'The student reads words accurately and understands the story, but reads at a slower pace. Practicing reading aloud will help them read more smoothly and effortlessly.';
      case 'comprehension':
        return 'The student can read the words smoothly and accurately, but has difficulty understanding or remembering key details. Discussing the story before and after reading will help.';
      default:
        return 'The student completed the reading assessment.';
    }
  }

  String get wordReadingLevel => getWordReadingLevel(accuracy);
  String get comprehensionLevel => getComprehensionLevel(comprehension);
  String get readingProfile => getReadingProfile(accuracy, comprehension);
  String get readingProfileExplanation =>
      getProfileExplanation(accuracy, comprehension);
  String get classificationExplanation =>
      getClassificationExplanation(classification);

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