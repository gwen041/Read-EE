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
          'Create Sections',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Class Sections',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add at least one section for each selected grade level.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    children: [
                      for (final grade in widget.selectedGrades) ...[
                        Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  grade,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controllers[grade],
                                        decoration: const InputDecoration(
                                          labelText: 'Section Name',
                                          hintText: 'e.g. Narra, Daisy, Amber',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        ),
                                        onSubmitted: (_) => addSection(grade),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () => addSection(grade),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: textPrimary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                if (sections[grade]!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 6.0,
                                    children: [
                                      for (final section in sections[grade]!)
                                        Chip(
                                          backgroundColor: const Color(0xFFFEF3C7),
                                          label: Text(
                                            section,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                          ),
                                          deleteIconColor: const Color(0xFFEF4444),
                                          onDeleted: () {
                                            setState(() {
                                              sections[grade]!.remove(section);
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : finishSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: textPrimary),
                          )
                        : const Text(
                            'FINISH SETUP',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}