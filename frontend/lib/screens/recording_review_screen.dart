import 'package:flutter/material.dart';

class RecordingReviewScreen extends StatelessWidget {
  final String studentName;
  final String materialTitle;
  final String passage;
  final String audioPath;

  const RecordingReviewScreen({
    super.key,
    required this.studentName,
    required this.materialTitle,
    required this.passage,
    required this.audioPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Recording'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              studentName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              materialTitle,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 25),

            const Text(
              'Recording Complete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'The student recording has been captured successfully.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Audio file:\n$audioPath',
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Quiz will be connected here later.
                },
                child: const Text('CONTINUE TO QUIZ'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('RECORD AGAIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}