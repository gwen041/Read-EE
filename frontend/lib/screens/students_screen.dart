import 'package:flutter/material.dart';
import '../models/class_section.dart';
import '../services/class_service.dart';
import 'import_students_dialog.dart';

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
  final TextEditingController studentController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    studentController.dispose();
    super.dispose();
  }

  Future<void> addStudent() async {
    final name = studentController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a student name.')),
      );
      return;
    }

    final alreadyExists = widget.classSection.students.any(
      (student) => student.fullName.toLowerCase() == name.toLowerCase(),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That student is already in this class.')),
      );
      return;
    }

    if (widget.classSection.id == null) return;

    setState(() => _isAdding = true);

    try {
      final newStudent = await ClassService.addStudent(
        classId: widget.classSection.id!,
        fullName: name,
      );

      setState(() {
        widget.classSection.students.add(newStudent);
        studentController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> importStudents() async {
    final currentNames =
        widget.classSection.students.map((s) => s.fullName).toList();

    final importedNames = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return Dialog(
          child: ImportStudentsDialog(
            classSection: widget.classSection,
            currentStudents: currentNames,
          ),
        );
      },
    );

    if (importedNames != null && importedNames.isNotEmpty && widget.classSection.id != null) {
      try {
        final updatedStudents = await ClassService.importStudents(
          classId: widget.classSection.id!,
          studentNames: importedNames,
        );

        setState(() {
          widget.classSection.students
            ..clear()
            ..addAll(updatedStudents);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported ${importedNames.length} students!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> deleteStudent(int index) async {
    final student = widget.classSection.students[index];
    if (widget.classSection.id == null) return;

    try {
      await ClassService.deleteStudent(
        classId: widget.classSection.id!,
        studentId: student.id,
      );

      setState(() {
        widget.classSection.students.removeAt(index);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = widget.classSection.students;

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
              '${widget.classSection.gradeLevel} - ${widget.classSection.sectionName}',
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
                  onPressed: _isAdding ? null : addStudent,
                  child: _isAdding
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ADD'),
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
                            title: Text(students[index].fullName),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => deleteStudent(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: importStudents,
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