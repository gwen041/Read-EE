import 'package:flutter/material.dart';
import '../models/class_section.dart';

class StudentsScreen extends StatefulWidget {
  final ClassSection classSection;

  const StudentsScreen({
    super.key,
    required this.classSection,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final List<String> students = [];

  final TextEditingController studentController =
      TextEditingController();

  @override
  void dispose() {
    studentController.dispose();
    super.dispose();
  }

  void addStudent() {
    final name = studentController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a student name.'),
        ),
      );
      return;
    }

    final alreadyExists = students.any(
      (student) => student.toLowerCase() == name.toLowerCase(),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That student is already in this class.'),
        ),
      );
      return;
    }

    setState(() {
      students.add(name);
      studentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classSection.sectionName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.classSection.gradeLevel} - '
              '${widget.classSection.sectionName}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '${students.length} students',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: studentController,
                    decoration: const InputDecoration(
                      labelText: 'Student Name',
                      hintText: 'Enter student name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addStudent(),
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed: addStudent,
                  child: const Text('ADD'),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Expanded(
              child: students.isEmpty
                  ? const Center(
                      child: Text(
                        'No students added yet.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(students[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  students.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Import feature will be added next.
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('IMPORT STUDENTS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}