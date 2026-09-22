import 'package:flutter/material.dart';
import '../models/class_section.dart';

class ClassesScreen extends StatelessWidget {
  final List<ClassSection> classes;

  const ClassesScreen({
    super.key,
    required this.classes,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ClassSection>> groupedClasses = {};

    for (final classSection in classes) {
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
        child: classes.isEmpty
            ? const Center(
                child: Text(
                  'No classes have been created yet.',
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView(
                children: [
                  const Text(
                    'My Classes',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'View and manage your grade levels and sections.',
                    style: TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 25),

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
                            'No students added yet',
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ],
              ),
      ),
    );
  }
}