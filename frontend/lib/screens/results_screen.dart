import 'package:flutter/material.dart';

import '../services/assessment_service.dart';

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
          answers.add(_getLetter(
            choice,
            [
              'The park',
              'The school',
              'The market',
              'The library',
            ],
          ));
        } else if (i == 1) {
          answers.add(_getLetter(
            choice,
            [
              'A red bag',
              'A lunch box',
              'A blue bag',
              'A book',
            ],
          ));
        } else if (i == 2) {
          answers.add(_getLetter(
            choice,
            [
              'In the afternoon',
              'At noon',
              'Late at night',
              'Early in the morning',
            ],
          ));
        } else if (i == 3) {
          answers.add(_getLetter(
            choice,
            [
              'His friend',
              'His teacher',
              'His brother',
              'His neighbor',
            ],
          ));
        } else if (i == 4) {
          answers.add(_getLetter(
            choice,
            [
              'He was prepared for school.',
              'He did not like school.',
              'He forgot his books.',
              'He was looking for his dog.',
            ],
          ));
        }
      }
    }

    return answers;
  }

  String _getLetter(String answer, List<String> choices) {
    final index = choices.indexOf(answer);

    if (index == -1) {
      return '';
    }

    return String.fromCharCode(65 + index);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Results'),
      ),
      body: Padding(
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
              style: const TextStyle(fontSize: 18),
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

            Card(
              child: ListTile(
                title: const Text('Reading Accuracy'),
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
                title: const Text('Words Per Minute'),
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
                title: const Text('Comprehension Score'),
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
                    classification.toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
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