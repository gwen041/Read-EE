import 'package:flutter/material.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  final String studentName;
  final String materialTitle;
  final String passage;
  final String audioPath;

  const QuizScreen({
    super.key,
    required this.studentName,
    required this.materialTitle,
    required this.passage,
    required this.audioPath,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Map<int, String> answers = {};

  final questions = [
    {
      'question': 'Where did the boy go?',
      'choices': [
        'He went to the park.',
        'He went to the school.',
        'He went to the store.',
        'He went to the library.',
      ],
    },
    {
      'question': 'Why do you think the boy went to school early?',
      'choices': [
        'He wanted to play outside.',
        'He wanted to arrive at school before his class started.',
        'He wanted to buy some food.',
        'He wanted to go back home.',
      ],
    },
    {
      'question': 'What can you tell about the boy from the story?',
      'choices': [
        'He was prepared for school.',
        'He did not like his teacher.',
        'He forgot his school books.',
        'He was going to the park.',
      ],
    },
    {
      'question':
          'What would most likely happen after the boy greeted his teacher?',
      'choices': [
        'He would enter his classroom.',
        'He would go back home.',
        'He would go to the store.',
        'He would take a nap.',
      ],
    },
    {
      'question': 'Which title would be best for the story?',
      'choices': [
        'A Morning at the Park',
        "The Boy's School Morning",
        'The Lost School Bag',
        'A Trip to the Store',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehension Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Comprehension Quiz',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${question['question']}',
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
                              children: [
                                ...List<String>.from(
                                  question['choices'] as List,
                                ).map(
                                  (choice) => RadioListTile<String>(
                                    title: Text(choice),
                                    value: choice,
                                  ),
                                ),
                              ],
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
              child: ElevatedButton(
                onPressed: () {
                  if (answers.length != questions.length) {
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
                        studentName: widget.studentName,
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