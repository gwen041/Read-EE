import 'package:flutter/material.dart';

import '../models/class_section.dart';

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

  final TextEditingController sectionController =
      TextEditingController();

  @override
  void dispose() {
    sectionController.dispose();
    super.dispose();
  }

  void addClass() {
    final sectionName = sectionController.text.trim();

    if (sectionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a section name.'),
        ),
      );
      return;
    }

    final sectionExists = widget.classes.any(
      (classSection) =>
          classSection.gradeLevel == selectedGrade &&
          classSection.sectionName.toLowerCase() ==
              sectionName.toLowerCase(),
    );

    if (sectionExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That section already exists for this grade.',
          ),
        ),
      );
      return;
    }

    final newClass = ClassSection(
      gradeLevel: selectedGrade,
      sectionName: sectionName,
    );

    Navigator.pop(context, newClass);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Class',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Grade Level',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: selectedGrade,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Grade 4',
                    child: Text('Grade 4'),
                  ),
                  DropdownMenuItem(
                    value: 'Grade 5',
                    child: Text('Grade 5'),
                  ),
                  DropdownMenuItem(
                    value: 'Grade 6',
                    child: Text('Grade 6'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedGrade = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Section Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Narra',
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: addClass,
                  child: const Text('ADD CLASS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}