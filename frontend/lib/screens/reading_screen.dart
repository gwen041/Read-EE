import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Assessment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reading Assessment',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Student',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a student',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Juan Dela Cruz',
                  child: Text('Juan Dela Cruz'),
                ),
                DropdownMenuItem(
                  value: 'Maria Santos',
                  child: Text('Maria Santos'),
                ),
                DropdownMenuItem(
                  value: 'Pedro Reyes',
                  child: Text('Pedro Reyes'),
                ),
              ],
              onChanged: (value) {},
            ),

            const SizedBox(height: 20),

            const Text(
              'Reading Passage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    'The little boy walked to the school early '
                    'in the morning. He carried his books in a '
                    'blue bag and greeted his teacher at the '
                    'classroom door.',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.mic),
                label: const Text('START RECORDING'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}