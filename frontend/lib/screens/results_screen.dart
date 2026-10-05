import 'package:flutter/material.dart';

import '../services/assessment_service.dart';
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
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();
    submitAssessment();
  }

  Future<void> submitAssessment() async {
    try {
      final studentAnswers = convertAnswersToLetters();

      final response = await AssessmentService.submitAssessment(
        audioPath: widget.audioPath,
        passage: widget.passage,
        studentAnswers: studentAnswers,
      );

      if (!mounted) return;

      setState(() {
        result = response;
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
    const correctAnswerLetters = [
      'B',
      'C',
      'D',
      'B',
      'A',
    ];

    final answers = <String>[];

    for (int i = 0; i < correctAnswerLetters.length; i++) {
      if (widget.answers[i] == null) {
        answers.add('');
      } else {
        final choice = widget.answers[i]!;

        if (i == 0) {
          answers.add(
            _getLetter(
              choice,
              [
                'The park',
                'The school',
                'The market',
                'The library',
              ],
            ),
          );
        } else if (i == 1) {
          answers.add(
            _getLetter(
              choice,
              [
                'A red bag',
                'A lunch box',
                'A blue bag',
                'A book',
              ],
            ),
          );
        } else if (i == 2) {
          answers.add(
            _getLetter(
              choice,
              [
                'In the afternoon',
                'At noon',
                'Late at night',
                'Early in the morning',
              ],
            ),
          );
        } else if (i == 3) {
          answers.add(
            _getLetter(
              choice,
              [
                'His friend',
                'His teacher',
                'His brother',
                'His neighbor',
              ],
            ),
          );
        } else if (i == 4) {
          answers.add(
            _getLetter(
              choice,
              [
                'He was prepared for school.',
                'He did not like school.',
                'He forgot his books.',
                'He was looking for his dog.',
              ],
            ),
          );
        }
      }
    }

    return answers;
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
      final finalResult =
          await AssessmentService.finalizeAssessment(
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
    final comprehension = result!['comprehension'];
    final classification = result!['classification'];

    final hasErrors = hasReadingErrors();

    final mismatches =
        (accuracy['mismatch_words'] as List?) ?? [];

    final missing =
        (accuracy['missing_words'] as List?) ?? [];

    final extra =
        (accuracy['extra_words'] as List?) ?? [];

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

            if (hasErrors) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                            fontWeight: FontWeight.bold,
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
                                '• ${getWordFromError(item)}',
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
                            fontWeight: FontWeight.bold,
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
                                '• ${getWordFromError(item)}',
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

            Card(
              child: ListTile(
                title: const Text(
                  'Reading Accuracy',
                ),
                trailing: Text(
                  '${accuracy['accuracy']}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Card(
              child: ListTile(
                title: const Text(
                  'Words Per Minute',
                ),
                trailing: Text(
                  '${wpm['wpm'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Card(
              child: ListTile(
                title: const Text(
                  'Comprehension Score',
                ),
                trailing: Text(
                  '${comprehension['score']}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Classification',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
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