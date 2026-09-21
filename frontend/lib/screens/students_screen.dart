import 'package:flutter/material.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = [
      {'name': 'Juan Dela Cruz', 'grade': 'Grade 4'},
      {'name': 'Maria Santos', 'grade': 'Grade 5'},
      {'name': 'Pedro Reyes', 'grade': 'Grade 6'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Students',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];

                  return Card(
                    child: ListTile(
                      title: Text(student['name']!),
                      subtitle: Text(student['grade']!),
                      trailing: const Icon(Icons.arrow_forward),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('ADD STUDENT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}