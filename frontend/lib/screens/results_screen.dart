import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../services/assessment_service.dart';
import '../services/assessment_store.dart';
import 'reading_verification_screen.dart';

class ResultsScreen extends StatefulWidget {
  final int? studentId;
  final String studentName;
  final int? materialId;
  final String materialTitle;
  final String passage;
  final String audioPath;
  final Map<int, String> answers;

  const ResultsScreen({
    super.key,
    this.studentId,
    required this.studentName,
    this.materialId,
    required this.materialTitle,
    required this.passage,
    required this.audioPath,
    required this.answers,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool isLoading = true;
  bool isFinalized = false;

  String? errorMessage;

  Map<String, dynamic>? result;

  // Keeps the original automated assessment.
  Map<String, dynamic>? initialResult;

  // Tracks the saved PostgreSQL Assessment ID so verification updates the same row.
  int? _savedAssessmentId;

  @override
  void initState() {
    super.initState();
    submitAssessment();
  }

  Future<void> submitAssessment() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final studentAnswers = convertAnswersToLetters();

      final response = await AssessmentService.submitAssessment(
        audioPath: widget.audioPath,
        passage: widget.passage,
        studentAnswers: studentAnswers,
        readingMaterialId: widget.materialId,
      );

      if (!mounted) return;

      setState(() {
        result = response;
        initialResult = response;
        isLoading = false;
      });

      await _persistAssessmentToDatabase();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _persistAssessmentToDatabase() async {
    if (result == null) return;
    if (widget.studentId == null || widget.materialId == null) return;

    try {
      final accuracy = Map<String, dynamic>.from(result!['accuracy']);
      final wpm = Map<String, dynamic>.from(result!['wpm']);
      final comprehension = Map<String, dynamic>.from(result!['comprehension']);
      final classification = result!['classification'].toString();

      final initialAccuracy = initialResult?['accuracy'];
      final initialAccuracyValue = initialAccuracy != null
          ? (initialAccuracy['accuracy'] as num).toDouble()
          : (accuracy['accuracy'] as num).toDouble();

      final accuracyDetails = {
        ...accuracy,
        'initialAccuracy': initialAccuracyValue,
        'isVerified': isFinalized,
        if (result!['reading_profile'] != null)
          'reading_profile': result!['reading_profile'],
      };

      if (_savedAssessmentId == null) {
        final saved = await AssessmentService.saveAssessment(
          studentId: widget.studentId!,
          readingMaterialId: widget.materialId!,
          accuracy: (accuracy['accuracy'] as num).toDouble(),
          wpm: (wpm['wpm'] as num).toDouble(),
          comprehensionScore: (comprehension['score'] as num).toDouble(),
          classification: classification,
          accuracyDetails: accuracyDetails,
          comprehensionDetails: comprehension,
        );
        _savedAssessmentId = saved.id;
      } else {
        await AssessmentService.updateAssessment(
          assessmentId: _savedAssessmentId!,
          accuracy: (accuracy['accuracy'] as num).toDouble(),
          wpm: (wpm['wpm'] as num).toDouble(),
          comprehensionScore: (comprehension['score'] as num).toDouble(),
          classification: classification,
          accuracyDetails: accuracyDetails,
          comprehensionDetails: comprehension,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Warning: Could not save assessment to database: '
            '${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  List<String> convertAnswersToLetters() {
    final answers = <String>[];

    for (int i = 0; i < 5; i++) {
      final selectedAnswer = widget.answers[i];

      if (selectedAnswer == null) {
        answers.add('');
        continue;
      }

      final upper = selectedAnswer.trim().toUpperCase();
      if (['A', 'B', 'C', 'D'].contains(upper)) {
        answers.add(upper);
        continue;
      }

      final letter = _getLetter(
        selectedAnswer,
        _getChoicesForQuestion(i),
      );

      answers.add(letter);
    }

    return answers;
  }

  List<String> _getChoicesForQuestion(int index) {
    switch (index) {
      case 0:
        return [
          'He went to the park.',
          'He went to the school.',
          'He went to the store.',
          'He went to the library.',
        ];

      case 1:
        return [
          'He wanted to play outside.',
          'He wanted to arrive at school before his class started.',
          'He wanted to buy some food.',
          'He wanted to go back home.',
        ];

      case 2:
        return [
          'He was prepared for school.',
          'He did not like his teacher.',
          'He forgot his school books.',
          'He was going to the park.',
        ];

      case 3:
        return [
          'He would enter his classroom.',
          'He would go back home.',
          'He would go to the store.',
          'He would take a nap.',
        ];

      case 4:
        return [
          'A Morning at the Park',
          "The Boy's School Morning",
          'The Lost School Bag',
          'A Trip to the Store',
        ];

      default:
        return [];
    }
  }

  String _getLetter(
    String answer,
    List<String> choices,
  ) {
    final index = choices.indexOf(answer);

    if (index == -1) {
      return '';
    }

    return String.fromCharCode(65 + index);
  }

  bool hasReadingErrors() {
    final accuracy = result?['accuracy'];

    if (accuracy == null) {
      return false;
    }

    final mismatches = accuracy['mismatch_words'] as List?;
    final missing = accuracy['missing_words'] as List?;
    final extra = accuracy['extra_words'] as List?;

    return (mismatches?.isNotEmpty ?? false) ||
        (missing?.isNotEmpty ?? false) ||
        (extra?.isNotEmpty ?? false);
  }

  Future<void> openReadingVerification(
    Map<String, dynamic> accuracy,
  ) async {
    final decisions = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingVerificationScreen(
          studentName: widget.studentName,
          materialTitle: widget.materialTitle,
          audioPath: widget.audioPath,
          accuracy: accuracy,
        ),
      ),
    );

    if (!mounted) return;

    if (decisions == null) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final finalResult = await AssessmentService.finalizeAssessment(
        accuracy: Map<String, dynamic>.from(
          result!['accuracy'],
        ),
        wpm: Map<String, dynamic>.from(
          result!['wpm'],
        ),
        comprehension: Map<String, dynamic>.from(
          result!['comprehension'],
        ),
        decisions: Map<int, bool>.from(
          decisions,
        ),
      );

      if (!mounted) return;

      setState(() {
        result = finalResult;
        isFinalized = true;
        isLoading = false;
      });

      await _persistAssessmentToDatabase();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reading verification completed. Final results updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  String getWordFromError(dynamic item) {
    if (item is Map) {
      return item['word']?.toString() ?? '';
    }

    return item.toString();
  }

  void saveAssessment() {
    if (result == null) {
      return;
    }

    final accuracy = Map<String, dynamic>.from(
      result!['accuracy'],
    );

    final wpm = Map<String, dynamic>.from(
      result!['wpm'],
    );

    final comprehension = Map<String, dynamic>.from(
      result!['comprehension'],
    );

    final classification = result!['classification'].toString();

    final initialAccuracy = initialResult?['accuracy'];

    final initialAccuracyValue = initialAccuracy != null
        ? (initialAccuracy['accuracy'] as num).toDouble()
        : (accuracy['accuracy'] as num).toDouble();

    AssessmentStore.addAssessment(
      Assessment(
        id: _savedAssessmentId,
        studentName: widget.studentName,
        materialTitle: widget.materialTitle,
        passage: widget.passage,
        date: DateTime.now(),
        initialAccuracy: initialAccuracyValue,
        accuracy: (accuracy['accuracy'] as num).toDouble(),
        wpm: (wpm['wpm'] as num).toDouble(),
        comprehension: (comprehension['score'] as num).toDouble(),
        classification: classification,
        isVerified: isFinalized,
      ),
    );
  }

  Widget buildResultCard({
    required String title,
    required String value,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getProfileColor(String profile) {
    switch (profile.toLowerCase().trim()) {
      case 'independent':
        return Colors.green;
      case 'instructional':
        return Colors.blue;
      case 'frustration':
        return Colors.orange.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getClassificationColor(String classification) {
    switch (classification.toLowerCase().trim()) {
      case 'normal':
        return Colors.green;
      case 'decoding':
        return Colors.orange.shade800;
      case 'fluency':
        return Colors.purple;
      case 'comprehension':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  Widget buildInteractiveBadgeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, color: color, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReadingProfileModal({
    required BuildContext context,
    required String wordLevel,
    required String compLevel,
    required String overallProfile,
    required String explanation,
    required double accuracyScore,
    required double comprehensionScore,
  }) {
    final color = _getProfileColor(overallProfile);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.auto_stories, color: color, size: 26),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Phil-IRI Reading Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Overall Reading Profile',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        overallProfile.toUpperCase(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Word Reading',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              wordLevel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${accuracyScore.round()}% accuracy',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Comprehension',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              compLevel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${comprehensionScore.round()}% score',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What this means:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        explanation,
                        style:
                            const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  void _showClassificationModal({
    required BuildContext context,
    required String classification,
    required String explanation,
  }) {
    final color = _getClassificationColor(classification);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.psychology, color: color, size: 26),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Reader Classification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Classification',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        classification.toUpperCase(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What this means:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        explanation,
                        style:
                            const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  Widget buildInitialAssessmentCard() {
    if (initialResult == null) {
      return const SizedBox.shrink();
    }

    final initialAccuracy = initialResult!['accuracy'];
    final initialWpm = initialResult!['wpm'];
    final initialComprehension = initialResult!['comprehension'];
    final initialClassification =
        initialResult!['classification']?.toString() ?? 'normal';

    final initialProfile = initialResult!['reading_profile'] != null
        ? Map<String, dynamic>.from(initialResult!['reading_profile'])
        : null;

    final accuracyScore =
        (initialAccuracy['accuracy'] as num).toDouble();
    final comprehensionScore =
        (initialComprehension['score'] as num).toDouble();

    final wordLevel = initialProfile?['word_reading_level']?.toString() ??
        Assessment.getWordReadingLevel(accuracyScore);
    final compLevel = initialProfile?['comprehension_level']?.toString() ??
        Assessment.getComprehensionLevel(comprehensionScore);
    final overallProfile = initialProfile?['reading_profile']?.toString() ??
        Assessment.getReadingProfile(accuracyScore, comprehensionScore);
    final profileExplanation = initialProfile?['explanation']?.toString() ??
        Assessment.getProfileExplanation(accuracyScore, comprehensionScore);

    final classExplanation = initialResult!['classification_explanation']?.toString() ??
        Assessment.getClassificationExplanation(initialClassification);

    final profileColor = _getProfileColor(overallProfile);
    final classColor = _getClassificationColor(initialClassification);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Initial Automated Assessment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Results generated from the initial speech recognition and assessment.',
            ),
            const SizedBox(height: 15),
            buildResultCard(
              title: 'Reading Accuracy',
              value: '${initialAccuracy['accuracy']}%',
            ),
            buildResultCard(
              title: 'Words Per Minute',
              value: '${initialWpm['wpm'].toStringAsFixed(2)}',
            ),
            buildResultCard(
              title: 'Comprehension Score',
              value: '${initialComprehension['score']}%',
            ),
            const SizedBox(height: 12),
            buildInteractiveBadgeCard(
              icon: Icons.auto_stories,
              title: 'Phil-IRI Reading Profile',
              subtitle: 'Tap to view details',
              badgeText: overallProfile,
              color: profileColor,
              onTap: () {
                _showReadingProfileModal(
                  context: context,
                  wordLevel: wordLevel,
                  compLevel: compLevel,
                  overallProfile: overallProfile,
                  explanation: profileExplanation,
                  accuracyScore: accuracyScore,
                  comprehensionScore: comprehensionScore,
                );
              },
            ),
            const SizedBox(height: 8),
            buildInteractiveBadgeCard(
              icon: Icons.psychology,
              title: 'Reader Classification',
              subtitle: 'Tap to view details',
              badgeText: initialClassification,
              color: classColor,
              onTap: () {
                _showClassificationModal(
                  context: context,
                  classification: initialClassification,
                  explanation: classExplanation,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFinalAssessmentCard(
    Map<String, dynamic> accuracy,
    Map<String, dynamic> wpm,
    Map<String, dynamic> comprehension,
    dynamic classification,
  ) {
    final profileData = result?['reading_profile'] != null
        ? Map<String, dynamic>.from(result!['reading_profile'])
        : null;
    final accuracyScore =
        (accuracy['accuracy'] as num).toDouble();
    final comprehensionScore =
        (comprehension['score'] as num).toDouble();

    final wordLevel = profileData?['word_reading_level']?.toString() ??
        Assessment.getWordReadingLevel(accuracyScore);
    final compLevel = profileData?['comprehension_level']?.toString() ??
        Assessment.getComprehensionLevel(comprehensionScore);
    final overallProfile = profileData?['reading_profile']?.toString() ??
        Assessment.getReadingProfile(accuracyScore, comprehensionScore);
    final profileExplanation = profileData?['explanation']?.toString() ??
        Assessment.getProfileExplanation(accuracyScore, comprehensionScore);

    final classStr = classification.toString();
    final classExplanation = result?['classification_explanation']?.toString() ??
        Assessment.getClassificationExplanation(classStr);

    final profileColor = _getProfileColor(overallProfile);
    final classColor = _getClassificationColor(classStr);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFinalized
                  ? 'Teacher-Verified Final Assessment'
                  : 'Assessment Results',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isFinalized) ...[
              const SizedBox(height: 8),
              const Text(
                'Final results after teacher verification of the reading errors.',
              ),
            ],
            const SizedBox(height: 15),
            buildResultCard(
              title: 'Reading Accuracy',
              value: '${accuracy['accuracy']}%',
            ),
            buildResultCard(
              title: 'Words Per Minute',
              value: '${wpm['wpm'].toStringAsFixed(2)}',
            ),
            buildResultCard(
              title: 'Comprehension Score',
              value: '${comprehension['score']}%',
            ),
            const SizedBox(height: 12),
            buildInteractiveBadgeCard(
              icon: Icons.auto_stories,
              title: 'Phil-IRI Reading Profile',
              subtitle: 'Tap to view details',
              badgeText: overallProfile,
              color: profileColor,
              onTap: () {
                _showReadingProfileModal(
                  context: context,
                  wordLevel: wordLevel,
                  compLevel: compLevel,
                  overallProfile: overallProfile,
                  explanation: profileExplanation,
                  accuracyScore: accuracyScore,
                  comprehensionScore: comprehensionScore,
                );
              },
            ),
            const SizedBox(height: 8),
            buildInteractiveBadgeCard(
              icon: Icons.psychology,
              title: 'Reader Classification',
              subtitle: 'Tap to view details',
              badgeText: classStr,
              color: classColor,
              onTap: () {
                _showClassificationModal(
                  context: context,
                  classification: classStr,
                  explanation: classExplanation,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assessment Results'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assessment Results'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage!.replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : submitAssessment,
                    icon: const Icon(Icons.refresh),
                    label: const Text('RETRY SUBMISSION'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final accuracy = result!['accuracy'];
    final wpm = result!['wpm'];
    final comprehension = result!['comprehension'];
    final classification = result!['classification'];

    final hasErrors = hasReadingErrors();

    final mismatches = (accuracy['mismatch_words'] as List?) ?? [];
    final missing = (accuracy['missing_words'] as List?) ?? [];
    final extra = (accuracy['extra_words'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.studentName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.materialTitle,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Assessment Results',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (isFinalized) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Verification Completed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The teacher reviewed the detected reading differences. '
                        'The final assessment below reflects the teacher verification.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              buildInitialAssessmentCard(),
              const SizedBox(height: 15),
            ],
            if (!isFinalized && hasErrors) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Verification Needed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The system detected possible reading differences. '
                        'Please review the recording before finalizing the assessment.',
                      ),
                      const SizedBox(height: 15),
                      if (mismatches.isNotEmpty)
                        ...mismatches.map(
                          (item) {
                            final mismatch = Map<String, dynamic>.from(
                              item as Map,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                'Expected: ${mismatch['expected']}  '
                                'Detected: ${mismatch['student']}',
                              ),
                            );
                          },
                        ),
                      if (missing.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        const Text(
                          'Missing words:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        ...missing.map(
                          (item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text('• ${getWordFromError(item)}'),
                            );
                          },
                        ),
                      ],
                      if (extra.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        const Text(
                          'Extra words:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        ...extra.map(
                          (item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text('• ${getWordFromError(item)}'),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            openReadingVerification(accuracy);
                          },
                          child: const Text('REVIEW READING ERRORS'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
            buildFinalAssessmentCard(
              accuracy,
              wpm,
              comprehension,
              classification,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  saveAssessment();

                  if (!kIsWeb) {
                    try {
                      final tempFile = File(widget.audioPath);
                      if (tempFile.existsSync()) {
                        tempFile.deleteSync();
                      }
                    } catch (_) {}
                  }

                  Navigator.popUntil(
                    context,
                    (route) =>
                        route.settings.name == '/dashboard' || route.isFirst,
                  );
                },
                child: const Text('BACK TO DASHBOARD'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}