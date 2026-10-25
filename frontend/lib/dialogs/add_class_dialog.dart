import 'package:flutter/material.dart';
import '../models/class_section.dart';
import '../services/class_service.dart';

class AddClassDialog extends StatefulWidget {
  final List<ClassSection> classes;

  const AddClassDialog({
    super.key,
    required this.classes,
  });

  @override
  State<AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<AddClassDialog> {
  String selectedGrade = 'Grade 4';
  final TextEditingController sectionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    sectionController.dispose();
    super.dispose();
  }

  Future<void> addClass() async {
    final sectionName = sectionController.text.trim();

    if (sectionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a section name.')),
      );
      return;
    }

    final sectionExists = widget.classes.any(
      (classSection) =>
          classSection.gradeLevel == selectedGrade &&
          classSection.sectionName.toLowerCase() == sectionName.toLowerCase(),
    );

    if (sectionExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That section already exists for this grade.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newClass = await ClassService.createSection(
        gradeLevel: selectedGrade,
        sectionName: sectionName,
      );

      if (!mounted) return;
      Navigator.pop(context, newClass);
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
    return AlertDialog(
      title: const Text('Add Class Section'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedGrade,
            decoration: const InputDecoration(
              labelText: 'Grade Level',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Grade 4', child: Text('Grade 4')),
              DropdownMenuItem(value: 'Grade 5', child: Text('Grade 5')),
              DropdownMenuItem(value: 'Grade 6', child: Text('Grade 6')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedGrade = value);
              }
            },
          ),
          const SizedBox(height: 15),
          TextField(
            controller: sectionController,
            decoration: const InputDecoration(
              labelText: 'Section Name',
              hintText: 'e.g. Narra, Daisy, Amber',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => addClass(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : addClass,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }
}
