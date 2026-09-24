import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../models/class_section.dart';

class ImportStudentsDialog extends StatefulWidget {
  final ClassSection classSection;
  final List<String> currentStudents;

  const ImportStudentsDialog({
    super.key,
    required this.classSection,
    required this.currentStudents,
  });

  @override
  State<ImportStudentsDialog> createState() =>
      _ImportStudentsDialogState();
}

class _ImportStudentsDialogState
    extends State<ImportStudentsDialog> {
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

    if (!mounted || file == null) {
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

    final existingNames = widget.currentStudents
        .map((student) => student.toLowerCase())
        .toSet();

    final importedNames = <String>{};
    final validStudents = <String>[];

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
    final totalDuplicates =
        duplicateCount + existingStudentCount;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: 600,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Import Students',
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

            Text(
              '${widget.classSection.gradeLevel} - '
              '${widget.classSection.sectionName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Use the READ-EE CSV template and paste only '
              'the student names.',
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: downloadTemplate,
                icon: const Icon(Icons.download),
                label: const Text(
                  'DOWNLOAD CSV TEMPLATE',
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: processImport,
                icon: const Icon(Icons.upload_file),
                label: const Text(
                  'SELECT CSV FILE',
                ),
              ),
            ),

            if (totalDuplicates > 0) ...[
              const SizedBox(height: 12),
              Text(
                '$totalDuplicates duplicate student(s) removed.',
                style: const TextStyle(
                  color: Colors.orange,
                ),
              ),
            ],

            const SizedBox(height: 20),

            const Text(
              'Students to Import',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

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
                            title: Text(
                              importedStudents[index],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('CANCEL'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: importedStudents.isEmpty
                        ? null
                        : confirmImport,
                    child: const Text(
                      'CONFIRM IMPORT',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}