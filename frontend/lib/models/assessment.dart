class Assessment {
  final int? id;
  final String studentName;
  final String materialTitle;
  final String passage;
  final DateTime date;

  final double accuracy;
  final double wpm;
  final double comprehension;
  final String classification;
  final bool isVerified;

  final double initialAccuracy;
  final double? initialWpm;
  final double? initialComprehension;
  final String? initialClassification;
  final String? initialReadingProfile;

  final int? gradeLevel;
  final String? sectionName;
  final int? studentId;
  final int? readingMaterialId;
  final String? audioPath;
  final Map<String, dynamic>? accuracyDetails;
  final Map<String, dynamic>? comprehensionDetails;

  Assessment({
    this.id,
    required this.studentName,
    required this.materialTitle,
    required this.passage,
    required this.date,
    required this.initialAccuracy,
    this.initialWpm,
    this.initialComprehension,
    this.initialClassification,
    this.initialReadingProfile,
    required this.accuracy,
    required this.wpm,
    required this.comprehension,
    required this.classification,
    required this.isVerified,
    this.gradeLevel,
    this.sectionName,
    this.studentId,
    this.readingMaterialId,
    this.audioPath,
    this.accuracyDetails,
    this.comprehensionDetails,
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

  String get displayClassification =>
    classification.isNotEmpty ? classification : 'Normal';
  String get initialDisplayClassification =>
    (initialClassification != null && initialClassification!.isNotEmpty)
      ? initialClassification!
      : displayClassification;

  String get initialReadingProfileFormatted =>
    initialReadingProfile ??
    getReadingProfile(initialAccuracy, initialComprehension ?? comprehension);

  String get formattedSection {
    if (sectionName == null || sectionName!.trim().isEmpty) return '';
    final name = sectionName!.trim();
    return name.toLowerCase().startsWith('section') ? name : 'Section $name';
  }

  String get gradeAndSection {
    final g = gradeLevel != null ? 'Grade $gradeLevel' : '';
    final s = formattedSection;
    if (g.isNotEmpty && s.isNotEmpty) return '$g - $s';
    if (g.isNotEmpty) return g;
    return s;
  }

  bool get hasErrorsToVerify {
    if (accuracyDetails == null) return false;
    final mismatches = accuracyDetails!['mismatch_words'] as List?;
    final missing = accuracyDetails!['missing_words'] as List?;
    final extra = accuracyDetails!['extra_words'] as List?;
    return (mismatches?.isNotEmpty ?? false) ||
        (missing?.isNotEmpty ?? false) ||
        (extra?.isNotEmpty ?? false);
  }

  int get totalErrorsCount {
    if (accuracyDetails == null) return 0;
    final mismatches =
        (accuracyDetails!['mismatch_words'] as List?)?.length ?? 0;
    final missing =
        (accuracyDetails!['missing_words'] as List?)?.length ?? 0;
    final extra =
        (accuracyDetails!['extra_words'] as List?)?.length ?? 0;
    return mismatches + missing + extra;
  }

  factory Assessment.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final classSection = student?['classSection'] as Map<String, dynamic>?;
    final material = json['readingMaterial'] as Map<String, dynamic>?;
    final accuracyDetails = json['accuracyDetails'] as Map<String, dynamic>?;
    final comprehensionDetails =
        json['comprehensionDetails'] as Map<String, dynamic>?;

    final finalAccuracy = (json['accuracy'] as num).toDouble();
    final initialAccuracy = accuracyDetails != null &&
            accuracyDetails['initialAccuracy'] != null
        ? (accuracyDetails['initialAccuracy'] as num).toDouble()
        : finalAccuracy;

    final initialWpm = accuracyDetails != null &&
            accuracyDetails['initialWpm'] != null
        ? (accuracyDetails['initialWpm'] as num).toDouble()
        : (json['wpm'] as num).toDouble();

    final initialComprehension = accuracyDetails != null &&
            accuracyDetails['initialComprehension'] != null
        ? (accuracyDetails['initialComprehension'] as num).toDouble()
        : (json['comprehensionScore'] as num).toDouble();

    final initialClassification = accuracyDetails != null &&
            accuracyDetails['initialClassification'] != null
        ? accuracyDetails['initialClassification'].toString()
        : json['classification']?.toString();

    final initialReadingProfile = accuracyDetails != null &&
            accuracyDetails['initialReadingProfile'] != null
        ? accuracyDetails['initialReadingProfile'].toString()
        : null;

    final isVerified = accuracyDetails != null &&
            accuracyDetails['isVerified'] != null
        ? accuracyDetails['isVerified'] as bool
        : false;

    final audioPath = accuracyDetails?['audioPath']?.toString();

    int? gradeLevel;
    if (classSection?['gradeLevel'] != null) {
      gradeLevel = int.tryParse(classSection!['gradeLevel'].toString());
    } else if (material?['gradeLevel'] != null) {
      gradeLevel = int.tryParse(material!['gradeLevel'].toString());
    } else if (json['gradeLevel'] != null) {
      gradeLevel = int.tryParse(json['gradeLevel'].toString());
    }

    final sectionName = classSection?['sectionName']?.toString() ??
        json['sectionName']?.toString();

    final studentId = json['studentId'] as int? ??
        (student?['id'] as int?);
    final readingMaterialId = json['readingMaterialId'] as int? ??
        (material?['id'] as int?);

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
      initialWpm: initialWpm,
      initialComprehension: initialComprehension,
      initialClassification: initialClassification,
      initialReadingProfile: initialReadingProfile,
      accuracy: finalAccuracy,
      wpm: (json['wpm'] as num).toDouble(),
      comprehension: (json['comprehensionScore'] as num).toDouble(),
      classification: json['classification']?.toString() ?? '',
      isVerified: isVerified,
      gradeLevel: gradeLevel,
      sectionName: sectionName,
      studentId: studentId,
      readingMaterialId: readingMaterialId,
      audioPath: audioPath,
      accuracyDetails: accuracyDetails,
      comprehensionDetails: comprehensionDetails,
    );
  }
}
