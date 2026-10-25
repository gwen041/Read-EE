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
  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);
  static const Color accentColor = Color(0xFFFEF3C7);

  bool isLoading = true;
  bool isFinalized = false;

  String? errorMessage;

  Map<String, dynamic>? result;

  Map<String, dynamic>? initialResult;

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
      final initialWpmValue = initialResult?['wpm'] != null
          ? (initialResult!['wpm']['wpm'] as num).toDouble()
          : (wpm['wpm'] as num).toDouble();
      final initialCompValue = initialResult?['comprehension'] != null
          ? (initialResult!['comprehension']['score'] as num).toDouble()
          : (comprehension['score'] as num).toDouble();
      final initialClassificationValue = initialResult?['classification']?.toString() ?? classification;
      final initialProfileValue = initialResult?['reading_profile']?['reading_profile']?.toString() ??
          Assessment.getReadingProfile(initialAccuracyValue, initialCompValue);

      final accuracyDetails = {
        ...accuracy,
        'initialAccuracy': initialAccuracyValue,
        'initialWpm': initialWpmValue,
        'initialComprehension': initialCompValue,
        'initialClassification': initialClassificationValue,
        'initialReadingProfile': initialProfileValue,
        'audioPath': widget.audioPath,
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

  String getShortClassificationLabel(String classification) {
    final c = classification.toLowerCase().trim();
    if (c.contains('decoding')) return 'DECODING';
    if (c.contains('fluency')) return 'FLUENCY';
    if (c.contains('comprehension')) return 'COMPREHENSION';
    return 'NORMAL / NO DIFFICULTY';
  }

  Color _getProfileColor(String profile) {
    switch (profile.toLowerCase().trim()) {
      case 'independent':
        return const Color(0xFF059669);
      case 'instructional':
        return const Color(0xFF0284C7);
      case 'frustration':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getClassificationColor(String classification) {
    final c = classification.toLowerCase().trim();
    if (c.contains('decoding')) return const Color(0xFFD97706);
    if (c.contains('fluency')) return const Color(0xFF4F46E5);
    if (c.contains('comprehension')) return const Color(0xFFC2410C);
    return const Color(0xFF047857);
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInteractiveBadgeCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          badgeText.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          title: const Text(
            'Phil-IRI Reading Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
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
                        style: TextStyle(fontSize: 12, color: textSecondary),
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
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Word Reading',
                              style: TextStyle(
                                  fontSize: 11, color: textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              wordLevel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '${accuracyScore.round()}% accuracy',
                              style: const TextStyle(
                                fontSize: 11,
                                color: textSecondary,
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
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Comprehension',
                              style: TextStyle(
                                  fontSize: 11, color: textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              compLevel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '${comprehensionScore.round()}% score',
                              style: const TextStyle(
                                fontSize: 11,
                                color: textSecondary,
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
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What this means:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        explanation,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: textPrimary,
                        ),
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
          title: const Text(
            'Difficulty Classification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
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
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        getShortClassificationLabel(classification),
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
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What this means:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        explanation,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: textPrimary,
                        ),
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
    final wpmScore = (initialWpm['wpm'] as num).toDouble();

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Initial System Assessment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Results generated by speech recognition before teacher review.',
            style: TextStyle(
              fontSize: 12.5,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Accuracy',
                  value: '${accuracyScore.round()}%',
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFF0F9FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  label: 'Speed',
                  value: '${wpmScore.round()} WPM',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF0D9488),
                  bgColor: const Color(0xFFF0FDFA),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  label: 'Comprehension',
                  value: '${comprehensionScore.round()}%',
                  icon: Icons.auto_stories_outlined,
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF5F3FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          buildInteractiveBadgeCard(
            title: 'DIFFICULTY CLASSIFICATION',
            subtitle: 'Tap to view details',
            badgeText: getShortClassificationLabel(initialClassification),
            color: classColor,
            onTap: () {
              _showClassificationModal(
                context: context,
                classification: initialClassification,
                explanation: classExplanation,
              );
            },
          ),
          const SizedBox(height: 8),

          buildInteractiveBadgeCard(
            title: 'PHIL-IRI READING PROFILE',
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
        ],
      ),
    );
  }

  Widget buildFinalAssessmentCard(
    dynamic accuracy,
    dynamic wpm,
    dynamic comprehension,
    dynamic classification,
  ) {
    final profile = result?['reading_profile'] != null
        ? Map<String, dynamic>.from(result!['reading_profile'])
        : null;

    final accuracyScore =
        (accuracy['accuracy'] as num).toDouble();
    final comprehensionScore =
        (comprehension['score'] as num).toDouble();
    final wpmScore = (wpm['wpm'] as num).toDouble();

    final wordLevel = profile?['word_reading_level']?.toString() ??
        Assessment.getWordReadingLevel(accuracyScore);
    final compLevel = profile?['comprehension_level']?.toString() ??
        Assessment.getComprehensionLevel(comprehensionScore);
    final overallProfile = profile?['reading_profile']?.toString() ??
        Assessment.getReadingProfile(accuracyScore, comprehensionScore);
    final profileExplanation = profile?['explanation']?.toString() ??
        Assessment.getProfileExplanation(accuracyScore, comprehensionScore);

    final classStr = classification.toString();
    final classExplanation = result?['classification_explanation']?.toString() ??
        Assessment.getClassificationExplanation(classStr);

    final profileColor = _getProfileColor(overallProfile);
    final classColor = _getClassificationColor(classStr);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFinalized ? 'Final Verified Assessment' : 'Assessment Summary',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFinalized
                ? 'Teacher-verified oral reading diagnosis and score evaluation.'
                : 'Current oral reading evaluation results.',
            style: const TextStyle(
              fontSize: 12.5,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Accuracy',
                  value: '${accuracyScore.round()}%',
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFF0F9FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  label: 'Speed',
                  value: '${wpmScore.round()} WPM',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF0D9488),
                  bgColor: const Color(0xFFF0FDFA),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  label: 'Comprehension',
                  value: '${comprehensionScore.round()}%',
                  icon: Icons.auto_stories_outlined,
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF5F3FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          buildInteractiveBadgeCard(
            title: 'DIFFICULTY CLASSIFICATION',
            subtitle: 'Tap to view details',
            badgeText: getShortClassificationLabel(classStr),
            color: classColor,
            onTap: () {
              _showClassificationModal(
                context: context,
                classification: classStr,
                explanation: classExplanation,
              );
            },
          ),
          const SizedBox(height: 8),

          buildInteractiveBadgeCard(
            title: 'PHIL-IRI READING PROFILE',
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          ),
          title: const Text(
            'Assessment Results',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          ),
          title: const Text(
            'Assessment Results',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage!.replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: textPrimary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : submitAssessment,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'RETRY SUBMISSION',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
        title: const Text(
          'Assessment Results',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: accentColor,
                        child: Text(
                          widget.studentName.isNotEmpty
                              ? widget.studentName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.studentName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  size: 14,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    widget.materialTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (isFinalized) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Teacher Verification Completed',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'The teacher reviewed the detected reading differences. The finalized assessment below reflects the verified results.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF047857),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  buildInitialAssessmentCard(),
                  const SizedBox(height: 14),
                ],

                if (!isFinalized && hasErrors) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.rate_review_outlined,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Reading Verification Recommended',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Possible reading differences were detected during automated speech evaluation. Review the recording to verify student miscues before finalizing.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFB45309),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => openReadingVerification(accuracy),
                            icon: const Icon(Icons.edit_note_rounded, size: 20),
                            label: const Text(
                              'REVIEW READING ERRORS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
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
                  height: 48,
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
                            route.settings.name == '/dashboard' ||
                            route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'BACK TO DASHBOARD',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
