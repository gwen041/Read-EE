import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../services/assessment_service.dart';
import '../services/assessment_store.dart';
import 'reading_verification_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String studentName;
  final String materialTitle;
  final String passage;
  final String audioPath;
  final Map<int, String> answers;

  const ResultsScreen({
    super.key,
    required this.studentName,
    required this.materialTitle,
    required this.passage,
    required this.audioPath,
    required this.answers,
  });

  @override
  State<ResultsScreen> createState() =>
      _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool isLoading = true;
  bool isFinalized = false;

  String? errorMessage;

  Map<String, dynamic>? result;

  // Keeps the original automated assessment.
  Map<String, dynamic>? initialResult;

  @override
  void initState() {
    super.initState();
    submitAssessment();
  }

  Future<void> submitAssessment() async {
    try {
      final studentAnswers = convertAnswersToLetters();

      final response =
          await AssessmentService.submitAssessment(
        audioPath: widget.audioPath,
        passage: widget.passage,
        studentAnswers: studentAnswers,
      );

      if (!mounted) return;

      setState(() {
        result = response;
        initialResult = response;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
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

    final mismatches =
        accuracy['mismatch_words'] as List?;

    final missing =
        accuracy['missing_words'] as List?;

    final extra =
        accuracy['extra_words'] as List?;

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
        builder: (context) =>
            ReadingVerificationScreen(
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
      final finalResult =
          await AssessmentService.finalizeAssessment(
        accuracy: Map<String, dynamic>.from(
          result!['accuracy'],
        ),
        wpm: Map<String, dynamic>.from(
          result!['wpm'],
        ),
        comprehension:
            Map<String, dynamic>.from(
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reading verification completed. '
            'Final results updated.',
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

    final accuracy =
        Map<String, dynamic>.from(
      result!['accuracy'],
    );

    final wpm =
        Map<String, dynamic>.from(
      result!['wpm'],
    );

    final comprehension =
        Map<String, dynamic>.from(
      result!['comprehension'],
    );

    final classification =
        result!['classification'].toString();

    final initialAccuracy =
        initialResult?['accuracy'];

    final initialAccuracyValue =
        initialAccuracy != null
            ? (initialAccuracy['accuracy'] as num)
                .toDouble()
            : (accuracy['accuracy'] as num)
                .toDouble();

    AssessmentStore.addAssessment(
      Assessment(
        studentName: widget.studentName,
        materialTitle: widget.materialTitle,
        passage: widget.passage,
        date: DateTime.now(),
        initialAccuracy: initialAccuracyValue,
        accuracy:
            (accuracy['accuracy'] as num)
                .toDouble(),
        wpm:
            (wpm['wpm'] as num)
                .toDouble(),
        comprehension:
            (comprehension['score'] as num)
                .toDouble(),
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

  Widget buildInitialAssessmentCard() {
    if (initialResult == null) {
      return const SizedBox.shrink();
    }

    final initialAccuracy =
        initialResult!['accuracy'];

    final initialWpm =
        initialResult!['wpm'];

    final initialComprehension =
        initialResult!['comprehension'];

    final initialClassification =
        initialResult!['classification'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
              'Results generated from the initial '
              'speech recognition and assessment.',
            ),

            const SizedBox(height: 15),

            buildResultCard(
              title: 'Reading Accuracy',
              value:
                  '${initialAccuracy['accuracy']}%',
            ),

            buildResultCard(
              title: 'Words Per Minute',
              value:
                  '${initialWpm['wpm'].toStringAsFixed(2)}',
            ),

            buildResultCard(
              title: 'Comprehension Score',
              value:
                  '${initialComprehension['score']}%',
            ),

            const SizedBox(height: 8),

            const Text(
              'Classification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    initialClassification
                        .toString()
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                'Final results after teacher verification '
                'of the reading errors.',
              ),
            ],

            const SizedBox(height: 15),

            buildResultCard(
              title: 'Reading Accuracy',
              value:
                  '${accuracy['accuracy']}%',
            ),

            buildResultCard(
              title: 'Words Per Minute',
              value:
                  '${wpm['wpm'].toStringAsFixed(2)}',
            ),

            buildResultCard(
              title: 'Comprehension Score',
              value:
                  '${comprehension['score']}%',
            ),

            const SizedBox(height: 8),

            const Text(
              'Classification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    classification
                        .toString()
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
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
          title: const Text(
            'Assessment Results',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Assessment Results',
          ),
        ),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24.0),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final accuracy = result!['accuracy'];
    final wpm = result!['wpm'];
    final comprehension =
        result!['comprehension'];
    final classification =
        result!['classification'];

    final hasErrors = hasReadingErrors();

    final mismatches =
        (accuracy['mismatch_words'] as List?) ??
            [];

    final missing =
        (accuracy['missing_words'] as List?) ??
            [];

    final extra =
        (accuracy['extra_words'] as List?) ??
            [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assessment Results',
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                  padding:
                      const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Verification Completed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'The teacher reviewed the detected '
                        'reading differences. The final '
                        'assessment below reflects the '
                        'teacher verification.',
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
                  padding:
                      const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Verification Needed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'The system detected possible reading '
                        'differences. Please review the recording '
                        'before finalizing the assessment.',
                      ),

                      const SizedBox(height: 15),

                      if (mismatches.isNotEmpty)
                        ...mismatches.map(
                          (item) {
                            final mismatch =
                                Map<String, dynamic>.from(
                              item as Map,
                            );

                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 5,
                              ),
                              child: Text(
                                'Expected: '
                                '${mismatch['expected']}  '
                                'Detected: '
                                '${mismatch['student']}',
                              ),
                            );
                          },
                        ),

                      if (missing.isNotEmpty) ...[
                        const SizedBox(height: 5),

                        const Text(
                          'Missing words:',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 3),

                        ...missing.map(
                          (item) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 3,
                              ),
                              child: Text(
                                '• '
                                '${getWordFromError(item)}',
                              ),
                            );
                          },
                        ),
                      ],

                      if (extra.isNotEmpty) ...[
                        const SizedBox(height: 5),

                        const Text(
                          'Extra words:',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 3),

                        ...extra.map(
                          (item) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 3,
                              ),
                              child: Text(
                                '• '
                                '${getWordFromError(item)}',
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            openReadingVerification(
                              accuracy,
                            );
                          },
                          child: const Text(
                            'REVIEW READING ERRORS',
                          ),
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

                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                },
                child: const Text(
                  'BACK TO DASHBOARD',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}