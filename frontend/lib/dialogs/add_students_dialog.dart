import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../models/class_section.dart';
import '../services/class_service.dart';

class AddStudentsDialog extends StatefulWidget {
  final ClassSection classSection;
  final VoidCallback onStudentsUpdated;

  const AddStudentsDialog({
    super.key,
    required this.classSection,
    required this.onStudentsUpdated,
  });

  @override
  State<AddStudentsDialog> createState() => _AddStudentsDialogState();
}

class _AddStudentsDialogState extends State<AddStudentsDialog> {
  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color accentColor = Color(0xFFFEF3C7);

  int _selectedTab = 0;

  final TextEditingController _nameController = TextEditingController();
  bool _isSavingSingle = false;

  final List<String> _importedNames = [];
  final List<String> _duplicatesInFile = [];
  final List<String> _alreadyExistingNames = [];
  bool _isProcessingCsv = false;
  bool _isSavingImport = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addSingleStudent() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a student name.')),
      );
      return;
    }

    final alreadyExists = widget.classSection.students.any(
      (s) => s.fullName.toLowerCase() == name.toLowerCase(),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That student is already in this section.')),
      );
      return;
    }

    if (widget.classSection.id == null) return;

    setState(() => _isSavingSingle = true);

    try {
      final newStudent = await ClassService.addStudent(
        classId: widget.classSection.id!,
        fullName: name,
      );

      widget.classSection.students.add(newStudent);
      widget.onStudentsUpdated();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newStudent.fullName} added successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSavingSingle = false);
    }
  }

  void _downloadCsvTemplate() {
    const csvContent = 'student_name\n';
    final blob = html.Blob([csvContent], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', 'read_ee_student_template.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  Future<void> _pickAndProcessCsv() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (!mounted || file == null) return;

    setState(() => _isProcessingCsv = true);

    try {
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes);
      final lines = content.split(RegExp(r'\r?\n'));

      if (lines.isEmpty || lines.first.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The selected CSV file is empty.')),
        );
        return;
      }

      final header = lines.first.trim().toLowerCase();
      if (header != 'student_name') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid template format. The CSV must have "student_name" as the first row.',
            ),
          ),
        );
        return;
      }

      final existingNames = widget.classSection.students
          .map((s) => s.fullName.toLowerCase())
          .toSet();

      final seenInFile = <String>{};
      final validStudents = <String>[];
      final duplicatesInFile = <String>[];
      final alreadyExisting = <String>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final normalized = line.toLowerCase();
        if (existingNames.contains(normalized)) {
          alreadyExisting.add(line);
        } else if (seenInFile.contains(normalized)) {
          duplicatesInFile.add(line);
        } else {
          seenInFile.add(normalized);
          validStudents.add(line);
        }
      }

      setState(() {
        _importedNames
          ..clear()
          ..addAll(validStudents);
        _duplicatesInFile
          ..clear()
          ..addAll(duplicatesInFile);
        _alreadyExistingNames
          ..clear()
          ..addAll(alreadyExisting);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to read CSV file.')),
      );
    } finally {
      if (mounted) setState(() => _isProcessingCsv = false);
    }
  }

  Future<void> _submitImportCsv() async {
    if (_importedNames.isEmpty || widget.classSection.id == null) return;

    setState(() => _isSavingImport = true);

    try {
      final updatedStudents = await ClassService.importStudents(
        classId: widget.classSection.id!,
        studentNames: _importedNames,
      );

      widget.classSection.students
        ..clear()
        ..addAll(updatedStudents);
      widget.onStudentsUpdated();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported ${_importedNames.length} students!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSavingImport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: textPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Add Students',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? primaryColor : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: _selectedTab == 0 ? textPrimary : textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Single Student',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                                color: _selectedTab == 0 ? textPrimary : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? primaryColor : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_rounded,
                              size: 16,
                              color: _selectedTab == 1 ? textPrimary : textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Import CSV',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                                color: _selectedTab == 1 ? textPrimary : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedTab == 0) ...[
                const Text(
                  'Student Full Name',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'e.g. Juan Dela Cruz',
                    hintStyle: const TextStyle(fontSize: 13, color: textSecondary),
                    filled: true,
                    fillColor: const Color(0xFFFAF9F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _addSingleStudent(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isSavingSingle ? null : _addSingleStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSavingSingle
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: textPrimary),
                          )
                        : const Text(
                            'ADD STUDENT',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ]

              else ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CSV File Requirements:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '• File must have a "student_name" column header.\n• One student name per line.',
                                style: TextStyle(fontSize: 11, color: textSecondary, height: 1.4),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _downloadCsvTemplate,
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text(
                                  'Download CSV Template',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: _isProcessingCsv ? null : _pickAndProcessCsv,
                            icon: const Icon(Icons.file_upload_outlined, size: 18),
                            label: Text(
                              _isProcessingCsv ? 'Reading file...' : 'Select CSV File',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),

                        if (_duplicatesInFile.isNotEmpty || _alreadyExistingNames.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_duplicatesInFile.length + _alreadyExistingNames.length} Skipped Duplicate(s)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_alreadyExistingNames.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '• Already in this class: ${_alreadyExistingNames.join(", ")}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                  ),
                                ],
                                if (_duplicatesInFile.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    '• Duplicate in CSV file: ${_duplicatesInFile.join(", ")}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        if (_importedNames.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Students to Import',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  '${_importedNames.length} ready',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF9F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _importedNames.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 11,
                                        backgroundColor: accentColor,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _importedNames[index],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              onPressed: _isSavingImport ? null : _submitImportCsv,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isSavingImport
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: textPrimary),
                                    )
                                  : Text(
                                      'CONFIRM IMPORT (${_importedNames.length} STUDENTS)',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                            ),
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
      ),
    );
  }
}
