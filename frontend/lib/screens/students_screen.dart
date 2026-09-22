import 'package:flutter/material.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final List<Map<String, String>> students = [
    {'name': 'Juan Dela Cruz', 'grade': 'Grade 4'},
    {'name': 'Maria Santos', 'grade': 'Grade 5'},
    {'name': 'Pedro Reyes', 'grade': 'Grade 6'},
  ];

  void addStudent() {
    final nameController = TextEditingController();
    String selectedGrade = 'Grade 4';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Student'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'Grade Level',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Grade 4',
                        child: Text('Grade 4'),
                      ),
                      DropdownMenuItem(
                        value: 'Grade 5',
                        child: Text('Grade 5'),
                      ),
                      DropdownMenuItem(
                        value: 'Grade 6',
                        child: Text('Grade 6'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedGrade = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      students.add({
                        'name': nameController.text.trim(),
                        'grade': selectedGrade,
                      });
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('ADD'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: ElevatedButton.icon(
                onPressed: addStudent,
                icon: const Icon(Icons.person_add),
                label: const Text('ADD STUDENT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}