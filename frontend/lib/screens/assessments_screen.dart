import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../services/assessment_store.dart';

class AssessmentsScreen extends StatelessWidget {
  const AssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Assessment> assessments =
        AssessmentStore.assessments;

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

            if (assessments.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No completed assessments yet.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: assessments.length,
                  itemBuilder: (context, index) {
                    final assessment = assessments[index];

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              assessment.studentName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              assessment.materialTitle,
                            ),

                            const SizedBox(height: 5),

                            Text(
                              _formatDate(
                                assessment.date,
                              ),
                            ),

                            const SizedBox(height: 15),

                            Text(
                              'Accuracy: '
                              '${assessment.accuracy}%',
                            ),

                            Text(
                              'WPM: '
                              '${assessment.wpm.toStringAsFixed(2)}',
                            ),

                            Text(
                              'Comprehension: '
                              '${assessment.comprehension}%',
                            ),

                            Text(
                              'Classification: '
                              '${assessment.classification}',
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}