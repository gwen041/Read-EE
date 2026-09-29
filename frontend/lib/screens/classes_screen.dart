import 'package:flutter/material.dart';

import '../models/class_section.dart';
import 'students_screen.dart';
import 'add_class_dialog.dart';

class ClassesScreen extends StatefulWidget {
  final List<ClassSection> classes;

  const ClassesScreen({
    super.key,
    required this.classes,
  });

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  Future<void> addClass() async {
    final newClass = await showDialog<ClassSection>(
      context: context,
      builder: (context) {
        return AddClassDialog(
          classes: widget.classes,
        );
      },
    );

    if (newClass != null && mounted) {
      setState(() {
        widget.classes.add(newClass);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ClassSection>> groupedClasses = {};

    for (final classSection in widget.classes) {
      groupedClasses
          .putIfAbsent(classSection.gradeLevel, () => [])
          .add(classSection);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Classes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addClass,
                icon: const Icon(Icons.add),
                label: const Text('ADD CLASS'),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'View and manage your grade levels and sections.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: widget.classes.isEmpty
                  ? const Center(
                      child: Text(
                        'No classes have been created yet.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final entry in groupedClasses.entries) ...[
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          for (final classSection in entry.value)
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.class_),
                                title: Text(
                                  classSection.sectionName,
                                ),
                                subtitle: const Text(
                                  'Manage students',
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StudentsScreen(
                                        classSection: classSection,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}