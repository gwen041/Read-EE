import 'package:flutter/material.dart';

import '../models/class_section.dart';
import 'quiz_screen.dart';

class ReadingScreen extends StatefulWidget {
  final List<ClassSection> classes;

  const ReadingScreen({
    super.key,
    required this.classes,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  ClassSection? selectedClass;
  String? selectedStudent;

  final materials = [
    {
      'title': 'The Little Boy',
      'passage':
          'The little boy walked to the school early in the morning. '
          'He carried his books in a blue bag and greeted his teacher '
          'at the classroom door.',
    },
    {
      'title': 'The Lost Dog',
      'passage':
          'A little girl looked for her lost dog around the neighborhood.',
    },
    {
      'title': 'A Day at School',
      'passage':
          'The students arrived at school and prepared for their lessons.',
    },
  ];

  int selectedMaterial = 0;

  @override
  Widget build(BuildContext context) {
    final material = materials[selectedMaterial];

    final students = selectedClass?.students ?? [];

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
              'Class Section',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<ClassSection>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a class section',
              ),
              initialValue: selectedClass,
              items: widget.classes.map((classSection) {
                return DropdownMenuItem<ClassSection>(
                  value: classSection,
                  child: Text(
                    '${classSection.gradeLevel} - '
                    '${classSection.sectionName}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClass = value;
                  selectedStudent = null;
                });
              },
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
              initialValue: selectedStudent,
              items: students.map((student) {
                return DropdownMenuItem<String>(
                  value: student,
                  child: Text(student),
                );
              }).toList(),
              onChanged: selectedClass == null || students.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        selectedStudent = value;
                      });
                    },
            ),

            const SizedBox(height: 20),

            const Text(
              'Reading Material',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              initialValue: selectedMaterial,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                materials.length,
                (index) {
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(materials[index]['title']!),
                  );
                },
              ),
              onChanged: (value) {
                setState(() {
                  selectedMaterial = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            Text(
              material['title']!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    material['passage']!,
                    style: const TextStyle(
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
                onPressed: selectedStudent == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const QuizScreen(),
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