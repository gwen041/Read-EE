import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Map<int, String> answers = {};

  final questions = [
    {
      'question': 'Where did the boy go?',
      'choices': ['The park', 'The school', 'The market', 'The library'],
    },
    {
      'question': 'What did the boy carry?',
      'choices': ['A red bag', 'A lunch box', 'A blue bag', 'A book'],
    },
    {
      'question': 'Why did the boy go to school early?',
      'choices': [
        'To meet his teacher',
        'To play with friends',
        'To go home',
        'To buy food',
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

                          ...List<String>.from(question['choices'] as List)
                              .map(
                                (choice) => RadioListTile<String>(
                                  title: Text(choice),
                                  value: choice,
                                  groupValue: answers[index],
                                  onChanged: (value) {
                                    setState(() {
                                      answers[index] = value!;
                                    });
                                  },
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
                  // Quiz submission will be connected later.
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