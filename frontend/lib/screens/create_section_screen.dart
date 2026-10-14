import 'package:flutter/material.dart';
import '../services/class_service.dart';
import 'dashboard_screen.dart';

class CreateSectionScreen extends StatefulWidget {
  final List<String> selectedGrades;

  const CreateSectionScreen({
    super.key,
    required this.selectedGrades,
  });

  @override
  State<CreateSectionScreen> createState() => _CreateSectionScreenState();
}

class _CreateSectionScreenState extends State<CreateSectionScreen> {
  final Map<String, List<String>> sections = {};
  final Map<String, TextEditingController> controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final grade in widget.selectedGrades) {
      sections[grade] = [];
      controllers[grade] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void addSection(String grade) {
    final controller = controllers[grade]!;
    final sectionName = controller.text.trim();

    if (sectionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a section name.')),
      );
      return;
    }

    final sectionExists = sections[grade]!.any(
      (section) => section.toLowerCase() == sectionName.toLowerCase(),
    );

    if (sectionExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That section already exists.')),
      );
      return;
    }

    setState(() {
      sections[grade]!.add(sectionName);
      controller.clear();
    });
  }

  Future<void> finishSetup() async {
    final missingGrades = widget.selectedGrades.where(
      (grade) => sections[grade]!.isEmpty,
    );

    if (missingGrades.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please create at least one section for ${missingGrades.join(', ')}.',
          ),
        ),
      );
      return;
    }

    final List<Map<String, String>> batchData = [];
    for (final entry in sections.entries) {
      for (final sectionName in entry.value) {
        batchData.add({
          'gradeLevel': entry.key,
          'sectionName': sectionName,
        });
      }
    }

    setState(() => _isSaving = true);

    try {
      final createdClasses = await ClassService.createSectionsBatch(batchData);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/dashboard'),
          builder: (context) => DashboardScreen(classes: createdClasses),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sections'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Class Sections',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add at least one section for each selected grade level.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: ListView(
                children: [
                  for (final grade in widget.selectedGrades) ...[
                    Text(
                      grade,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers[grade],
                            decoration: const InputDecoration(
                              labelText: 'Section Name',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => addSection(grade),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => addSection(grade),
                          child: const Text('ADD'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        for (final section in sections[grade]!)
                          Chip(
                            label: Text(section),
                            onDeleted: () {
                              setState(() {
                                sections[grade]!.remove(section);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : finishSetup,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('FINISH SETUP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}