import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';

import '../models/class_section.dart';

class ImportStudentsScreen extends StatefulWidget {
  final ClassSection classSection;
  final List<String> currentStudents;

  const ImportStudentsScreen({
    super.key,
    required this.classSection,
    required this.currentStudents,
  });

  @override
  State<ImportStudentsScreen> createState() => _ImportStudentsScreenState();
}

class _ImportStudentsScreenState extends State<ImportStudentsScreen> {
  final List<String> importedStudents = [];

  int duplicateCount = 0;
  int existingStudentCount = 0;

  void downloadTemplate() {
    const csvContent = 'student_name\n';

    final blob = html.Blob(
      [csvContent],
      'text/csv',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'read_ee_student_template.csv',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  Future<void> processImport() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (!mounted) {
      return;
    }

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();

    if (!mounted) {
      return;
    }

    final content = utf8.decode(bytes);
    final lines = content.split(RegExp(r'\r?\n'));

    if (lines.isEmpty || lines.first.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The file is empty.'),
        ),
      );
      return;
    }

    final header = lines.first.trim().toLowerCase();

    if (header != 'student_name') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid template. Please use the READ-EE student template.',
          ),
        ),
      );
      return;
    }

    final Set<String> existingNames = widget.currentStudents
        .map((student) => student.toLowerCase())
        .toSet();

    final Set<String> importedNames = {};
    final List<String> validStudents = [];

    int duplicates = 0;
    int existing = 0;

    for (final line in lines.skip(1)) {
      final name = line.trim();

      if (name.isEmpty) {
        continue;
      }

      final normalizedName = name.toLowerCase();

      if (existingNames.contains(normalizedName)) {
        existing++;
        continue;
      }

      if (importedNames.contains(normalizedName)) {
        duplicates++;
        continue;
      }

      importedNames.add(normalizedName);
      validStudents.add(name);
    }

    setState(() {
      importedStudents
        ..clear()
        ..addAll(validStudents);

      duplicateCount = duplicates;
      existingStudentCount = existing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${validStudents.length} students ready for review.',
        ),
      ),
    );
  }

  void confirmImport() {
    Navigator.pop(context, importedStudents);
  }

  @override
  Widget build(BuildContext context) {
    final totalDuplicates = duplicateCount + existingStudentCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Students'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.classSection.gradeLevel} - '
              '${widget.classSection.sectionName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Import students using the READ-EE CSV template.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: downloadTemplate,
                icon: const Icon(Icons.download),
                label: const Text('DOWNLOAD CSV TEMPLATE'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: processImport,
                icon: const Icon(Icons.upload_file),
                label: const Text('SELECT CSV FILE'),
              ),
            ),

            if (totalDuplicates > 0) ...[
              const SizedBox(height: 15),
              Text(
                '$totalDuplicates duplicate student(s) removed.',
                style: const TextStyle(
                  color: Colors.orange,
                ),
              ),
            ],

            const SizedBox(height: 25),

            const Text(
              'Students to Import',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: importedStudents.isEmpty
                  ? const Center(
                      child: Text(
                        'No students ready for import.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: importedStudents.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(importedStudents[index]),
                          ),
                        );
                      },
                    ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    importedStudents.isEmpty ? null : confirmImport,
                child: const Text('CONFIRM IMPORT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}