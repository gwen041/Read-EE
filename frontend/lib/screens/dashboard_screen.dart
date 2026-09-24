import 'package:flutter/material.dart';

import '../models/class_section.dart';
import 'materials_screen.dart';
import 'reading_screen.dart';
import 'assessments_screen.dart';
import 'classes_screen.dart';

class DashboardScreen extends StatefulWidget {
  final List<ClassSection> classes;

  const DashboardScreen({
    super.key,
    this.classes = const [],
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int get totalStudents {
    int total = 0;

    for (final classSection in widget.classes) {
      total += classSection.students.length;
    }

    return total;
  }

  Future<void> openClasses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassesScreen(
          classes: widget.classes,
        ),
      ),
    );

    // Rebuild the dashboard after returning from My Classes.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('READ-EE Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Manage students and reading assessments.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            'Students',
                            style: TextStyle(fontSize: 18),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            '$totalStudents',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: const [
                          Text(
                            'Assessments',
                            style: TextStyle(fontSize: 18),
                          ),

                          SizedBox(height: 10),

                          Text(
                            '0',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: openClasses,
              child: const Text('MY CLASSES'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaterialsScreen(),
                  ),
                );
              },
              child: const Text('Reading Materials'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReadingScreen(),
                  ),
                );
              },
              child: const Text('START ASSESSMENT'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssessmentsScreen(),
                  ),
                );
              },
              child: const Text('View Assessments'),
            ),
          ],
        ),
      ),
    );
  }
}