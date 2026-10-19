import 'package:flutter/material.dart';
import '../models/reading_material.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  final int? studentId;
  final String studentName;
  final int? materialId;
  final String materialTitle;
  final String passage;
  final String audioPath;
  final List<ComprehensionQuestionItem> questions;

  const QuizScreen({
    super.key,
    this.studentId,
    required this.studentName,
    this.materialId,
    required this.materialTitle,
    required this.passage,
    required this.audioPath,
    this.questions = const [],
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Map<int, String> answers = {}; // Stores 'A', 'B', 'C', or 'D' per question index

  @override
  Widget build(BuildContext context) {
    final quizQuestions = widget.questions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehension Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Comprehension Quiz: ${widget.materialTitle}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: quizQuestions.length,
                itemBuilder: (context, index) {
                  final q = quizQuestions[index];
                  final choices = [
                    {'letter': 'A', 'text': q.choiceA},
                    {'letter': 'B', 'text': q.choiceB},
                    {'letter': 'C', 'text': q.choiceC},
                    {'letter': 'D', 'text': q.choiceD},
                  ];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${q.questionText}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RadioGroup<String>(
                            groupValue: answers[index],
                            onChanged: (value) {
                              setState(() {
                                answers[index] = value!;
                              });
                            },
                            child: Column(
                              children: choices.map((choice) {
                                final letter = choice['letter']!;
                                final text = choice['text']!;
                                return RadioListTile<String>(
                                  title: Text('$letter. $text'),
                                  value: letter,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (answers.length != quizQuestions.length) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please answer all questions before submitting.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultsScreen(
                        studentId: widget.studentId,
                        studentName: widget.studentName,
                        materialId: widget.materialId,
                        materialTitle: widget.materialTitle,
                        passage: widget.passage,
                        audioPath: widget.audioPath,
                        answers: answers,
                      ),
                    ),
                  );
                },
                child: const Text('SUBMIT QUIZ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}