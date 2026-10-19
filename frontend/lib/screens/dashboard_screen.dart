import 'package:flutter/material.dart';
import '../models/class_section.dart';
import '../services/assessment_service.dart';
import '../services/auth_service.dart';
import '../services/class_service.dart';
import 'materials_screen.dart';
import 'reading_screen.dart';
import 'assessments_screen.dart';
import 'classes_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final List<ClassSection>? classes;

  const DashboardScreen({
    super.key,
    this.classes,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ClassSection> _classes = [];
  int _assessmentCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.classes != null && widget.classes!.isNotEmpty) {
      _classes = widget.classes!;
      _isLoading = false;
      _loadDashboardData(showSpinner: false);
    } else {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() => _isLoading = true);
    }
    try {
      final fetchedClasses = await ClassService.getClasses();
      final fetchedAssessments = await AssessmentService.getAssessments();
      if (!mounted) return;
      setState(() {
        _classes = fetchedClasses;
        _assessmentCount = fetchedAssessments.length;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int get totalStudents {
    int total = 0;
    for (final classSection in _classes) {
      total += classSection.students.length;
    }
    return total;
  }

  int get totalAssessments {
    return _assessmentCount;
  }

  Future<void> openClasses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassesScreen(
          classes: _classes,
        ),
      ),
    );
    _loadDashboardData(showSpinner: false);
  }

  Future<void> openReadingAssessment() async {
    if (_classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one class and student first.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingScreen(
          classes: _classes,
        ),
      ),
    );
    _loadDashboardData(showSpinner: false);
  }

  void openMaterials() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MaterialsScreen(),
      ),
    );
  }

  Future<void> openAssessments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssessmentsScreen(),
      ),
    );
    _loadDashboardData(showSpinner: false);
  }

  void handleLogout() {
    AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherName = AuthService.currentTeacher?['fullName'] ?? 'Teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('READ-EE Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $teacherName!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Reading Assessment and Fluency Tracker',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Total Classes',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${_classes.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Total Students',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '$totalStudents',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Assessments',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '$totalAssessments',
                                  style: const TextStyle(
                                    fontSize: 24,
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
                  const SizedBox(height: 25),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        Card(
                          child: InkWell(
                            onTap: openReadingAssessment,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic, size: 48),
                                  SizedBox(height: 10),
                                  Text(
                                    'Start Reading Assessment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Card(
                          child: InkWell(
                            onTap: openClasses,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.class_, size: 48),
                                  SizedBox(height: 10),
                                  Text(
                                    'My Classes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Card(
                          child: InkWell(
                            onTap: openMaterials,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.menu_book, size: 48),
                                  SizedBox(height: 10),
                                  Text(
                                    'Reading Materials',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Card(
                          child: InkWell(
                            onTap: openAssessments,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.assessment, size: 48),
                                  SizedBox(height: 10),
                                  Text(
                                    'Assessment History',
                                    style: TextStyle(
                                      fontSize: 18,
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
                  ),
                ],
              ),
            ),
    );
  }
}