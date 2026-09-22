import 'package:flutter/material.dart';
import 'create_section_screen.dart';

class TeacherSetupScreen extends StatefulWidget {
  const TeacherSetupScreen({super.key});

  @override
  State<TeacherSetupScreen> createState() => _TeacherSetupScreenState();
}

class _TeacherSetupScreenState extends State<TeacherSetupScreen> {
  final Set<String> selectedGrades = {};

  void toggleGrade(String grade) {
    setState(() {
      if (selectedGrades.contains(grade)) {
        selectedGrades.remove(grade);
      } else {
        selectedGrades.add(grade);
      }
    });
  }

  void continueSetup() {
    if (selectedGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one grade level.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSectionScreen(
          selectedGrades: selectedGrades.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Up Your Classes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Select the grade levels you currently handle.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            const Text(
              'Grade Levels',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            CheckboxListTile(
              title: const Text('Grade 4'),
              value: selectedGrades.contains('Grade 4'),
              onChanged: (_) {
                toggleGrade('Grade 4');
              },
            ),

            CheckboxListTile(
              title: const Text('Grade 5'),
              value: selectedGrades.contains('Grade 5'),
              onChanged: (_) {
                toggleGrade('Grade 5');
              },
            ),

            CheckboxListTile(
              title: const Text('Grade 6'),
              value: selectedGrades.contains('Grade 6'),
              onChanged: (_) {
                toggleGrade('Grade 6');
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: continueSetup,
                child: const Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}