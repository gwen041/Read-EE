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
  final Map<int, String> answers = {};

  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);

  @override
  Widget build(BuildContext context) {
    final quizQuestions = widget.questions;

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
          'Comprehension Quiz',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.quiz_rounded,
                              color: textPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.materialTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Student: ${widget.studentName} • 5 Multiple Choice Questions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${q.questionText}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
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
                                      title: Text(
                                        '$letter. $text',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: textPrimary,
                                        ),
                                      ),
                                      value: letter,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SUBMIT QUIZ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
