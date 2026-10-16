import 'package:flutter/material.dart';
import '../models/class_section.dart';
import '../models/reading_material.dart';
import '../services/material_service.dart';
import 'recording_screen.dart';

class ReadingScreen extends StatefulWidget {
  final List<ClassSection> classes;

  const ReadingScreen({
    super.key,
    required this.classes,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  ClassSection? selectedClass;
  StudentItem? selectedStudent;
  ReadingMaterialItem? selectedMaterial;

  List<ReadingMaterialItem> _allMaterials = [];
  bool _isLoadingMaterials = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      final fetched = await MaterialService.getMaterials();
      if (!mounted) return;
      setState(() {
        _allMaterials = fetched;
        _isLoadingMaterials = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMaterials = false);
    }
  }

  int? _extractGradeNumber(String? gradeStr) {
    if (gradeStr == null) return null;
    final match = RegExp(r'\d+').firstMatch(gradeStr);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  List<ReadingMaterialItem> get filteredMaterials {
    if (selectedClass == null) return [];
    final gradeNum = _extractGradeNumber(selectedClass!.gradeLevel);
    return _allMaterials.where((m) => m.gradeLevel == gradeNum).toList();
  }

  @override
  Widget build(BuildContext context) {
    final students = selectedClass?.students ?? [];
    final availableMaterials = filteredMaterials;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Assessment'),
      ),
      body: _isLoadingMaterials
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reading Assessment',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Class Section',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ClassSection>(
                    key: ValueKey(selectedClass),
                    initialValue: selectedClass,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a class section',
                    ),
                    items: widget.classes.map((classSection) {
                      return DropdownMenuItem<ClassSection>(
                        value: classSection,
                        child: Text(
                          '${classSection.gradeLevel} - ${classSection.sectionName}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                        selectedStudent = null;
                        final mats = filteredMaterials;
                        selectedMaterial = mats.isNotEmpty ? mats.first : null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Student',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<StudentItem>(
                    key: ValueKey(selectedStudent),
                    initialValue: selectedStudent,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a student',
                    ),
                    items: students.map((student) {
                      return DropdownMenuItem<StudentItem>(
                        value: student,
                        child: Text(student.fullName),
                      );
                    }).toList(),
                    onChanged: selectedClass == null || students.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              selectedStudent = value;
                            });
                          },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Reading Material',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ReadingMaterialItem>(
                    key: ValueKey(selectedMaterial),
                    initialValue: selectedMaterial,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: selectedClass == null
                          ? 'Select a class section first'
                          : availableMaterials.isEmpty
                              ? 'No materials for this grade level'
                              : 'Select reading material',
                    ),
                    items: availableMaterials.map((mat) {
                      return DropdownMenuItem<ReadingMaterialItem>(
                        value: mat,
                        child: Text(mat.title),
                      );
                    }).toList(),
                    onChanged:
                        selectedClass == null || availableMaterials.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  selectedMaterial = value;
                                });
                              },
                  ),
                  const SizedBox(height: 20),
                  if (selectedMaterial != null) ...[
                    Text(
                      selectedMaterial!.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            selectedMaterial!.passage,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Select a class section and reading material to preview the passage.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed:
                          selectedStudent == null || selectedMaterial == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RecordingScreen(
                                        studentId: selectedStudent!.id,
                                        studentName: selectedStudent!.fullName,
                                        materialId: selectedMaterial!.id,
                                        materialTitle: selectedMaterial!.title,
                                        passage: selectedMaterial!.passage,
                                        questions: selectedMaterial!.questions,
                                      ),
                                    ),
                                  );
                                },
                      icon: const Icon(Icons.mic),
                      label: const Text('START RECORDING'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}