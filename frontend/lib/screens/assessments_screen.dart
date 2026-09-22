import 'package:flutter/material.dart';

class AssessmentsScreen extends StatelessWidget {
  const AssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assessments = [
      {
        'student': 'Juan Dela Cruz',
        'date': 'September 22, 2026',
        'accuracy': '92.59%',
        'wpm': '114.87',
        'comprehension': '100%',
        'classification': 'Normal',
      },
      {
        'student': 'Maria Santos',
        'date': 'September 21, 2026',
        'accuracy': '85.00%',
        'wpm': '98.50',
        'comprehension': '80%',
        'classification': 'Fluency',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessments'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assessment History',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: assessments.length,
                itemBuilder: (context, index) {
                  final assessment = assessments[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assessment['student']!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(assessment['date']!),
                          const SizedBox(height: 15),

                          Text(
                            'Accuracy: ${assessment['accuracy']}',
                          ),
                          Text(
                            'WPM: ${assessment['wpm']}',
                          ),
                          Text(
                            'Comprehension: ${assessment['comprehension']}',
                          ),
                          Text(
                            'Classification: ${assessment['classification']}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}