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

  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);

  @override
  Widget build(BuildContext context) {
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
          'Teacher Setup',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Up Your Classes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select the grade levels you currently handle.',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Grade Levels',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Grade 4', style: TextStyle(color: textPrimary)),
                      value: selectedGrades.contains('Grade 4'),
                      activeColor: primaryColor,
                      checkColor: textPrimary,
                      onChanged: (_) => toggleGrade('Grade 4'),
                    ),
                    CheckboxListTile(
                      title: const Text('Grade 5', style: TextStyle(color: textPrimary)),
                      value: selectedGrades.contains('Grade 5'),
                      activeColor: primaryColor,
                      checkColor: textPrimary,
                      onChanged: (_) => toggleGrade('Grade 5'),
                    ),
                    CheckboxListTile(
                      title: const Text('Grade 6', style: TextStyle(color: textPrimary)),
                      value: selectedGrades.contains('Grade 6'),
                      activeColor: primaryColor,
                      checkColor: textPrimary,
                      onChanged: (_) => toggleGrade('Grade 6'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: continueSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: textPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}