import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../services/material_service.dart';

class AddMaterialDialog extends StatefulWidget {
  final int initialGrade;
  final VoidCallback onMaterialAdded;

  const AddMaterialDialog({
    super.key,
    required this.initialGrade,
    required this.onMaterialAdded,
  });

  @override
  State<AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<AddMaterialDialog> {
  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color accentColor = Color(0xFFFEF3C7);

  int _selectedTab = 0;

  late int _singleGrade;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _passageController = TextEditingController();
  final List<TextEditingController> _questionControllers =
      List.generate(5, (_) => TextEditingController());
  final List<List<TextEditingController>> _choiceControllers = List.generate(
    5,
    (_) => List.generate(4, (_) => TextEditingController()),
  );
  final List<String> _correctAnswers = List.filled(5, 'A');
  bool _isSavingSingle = false;

  bool _isProcessingCsv = false;
  bool _isSavingImport = false;
  String? _csvFileName;
  List<_ParsedMaterialRow> _parsedMaterials = [];
  String? _csvError;

  @override
  void initState() {
    super.initState();
    _singleGrade = widget.initialGrade;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _passageController.dispose();
    for (final c in _questionControllers) {
      c.dispose();
    }
    for (final row in _choiceControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _downloadCsvTemplate() {
    const csvContent =
        'grade_level,title,passage,q1_question,q1_choice_a,q1_choice_b,q1_choice_c,q1_choice_d,q1_answer,q2_question,q2_choice_a,q2_choice_b,q2_choice_c,q2_choice_d,q2_answer,q3_question,q3_choice_a,q3_choice_b,q3_choice_c,q3_choice_d,q3_answer,q4_question,q4_choice_a,q4_choice_b,q4_choice_c,q4_choice_d,q4_answer,q5_question,q5_choice_a,q5_choice_b,q5_choice_c,q5_choice_d,q5_answer\n'
        '4,"The Little Red Hen","Once upon a time, a little red hen found a grain of wheat. She asked the other animals on the farm to help her plant it, but they all said no. So she planted it herself. When the wheat was ripe, she asked them to help harvest it, but they said no. Finally, she baked delicious bread with the wheat. When the bread was ready, the animals wanted to eat it, but the hen ate it with her chicks.","What did the hen find?","A corn seed","A grain of wheat","An apple","A coin",B,"Who helped the hen plant the wheat?","The duck","The cat","Nobody","The pig",C,"What did the hen make with the wheat?","Cereal","Cake","Bread","Soup",C,"Why didn\'t the other animals get any bread?","They were allergic","They didn\'t help","They were asleep","The bread was spoiled",B,"What is the lesson of the story?","Always be lazy","Hard work brings rewards","Chickens are selfish","Animals should live alone",B\n';

    final blob = html.Blob([csvContent], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', 'read_ee_materials_template.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            currentField.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
        } else if (char == '\n') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
          if (currentRow.any((f) => f.isNotEmpty)) {
            rows.add(List.from(currentRow));
          }
          currentRow.clear();
        } else if (char == '\r') {

        } else {
          currentField.write(char);
        }
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      if (currentRow.any((f) => f.isNotEmpty)) {
        rows.add(List.from(currentRow));
      }
    }

    return rows;
  }

  Future<void> _pickAndProcessCsv() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (!mounted || file == null) return;

    setState(() {
      _isProcessingCsv = true;
      _csvFileName = file.name;
      _csvError = null;
      _parsedMaterials = [];
    });

    try {
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes);
      final rows = _parseCsv(content);

      if (rows.isEmpty || rows.length < 2) {
        if (!mounted) return;
        setState(() {
          _isProcessingCsv = false;
          _csvError =
              'The selected CSV file has no data rows. Please use our template.';
        });
        return;
      }

      final header = rows.first
          .map((h) => h.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_'))
          .toList();

      int findCol(List<String> aliases) {
        for (final alias in aliases) {
          final idx = header.indexOf(alias);
          if (idx != -1) return idx;
        }
        return -1;
      }

      final gradeIdx = findCol(['grade_level', 'grade']);
      final titleIdx = findCol(['title', 'material_title']);
      final passageIdx =
          findCol(['passage', 'reading_passage', 'story', 'text']);

      if (titleIdx == -1 || passageIdx == -1) {
        if (!mounted) return;
        setState(() {
          _isProcessingCsv = false;
          _csvError =
              'Required columns "title" and "passage" not found. Please use the CSV template.';
        });
        return;
      }

      final qIndices = <int, _QuestionColIndices>{};
      for (int q = 1; q <= 5; q++) {
        final qTextIdx =
            findCol(['q${q}_question', 'q${q}_text', 'q$q', 'question_$q']);
        final cAIdx = findCol(
            ['q${q}_choice_a', 'q${q}_a', 'choice_${q}_a', 'q${q}_choicea']);
        final cBIdx = findCol(
            ['q${q}_choice_b', 'q${q}_b', 'choice_${q}_b', 'q${q}_choiceb']);
        final cCIdx = findCol(
            ['q${q}_choice_c', 'q${q}_c', 'choice_${q}_c', 'q${q}_choicec']);
        final cDIdx = findCol(
            ['q${q}_choice_d', 'q${q}_d', 'choice_${q}_d', 'q${q}_choiced']);
        final ansIdx = findCol([
          'q${q}_answer',
          'q${q}_correct',
          'q${q}_ans',
          'q${q}_correct_answer',
          'answer_$q'
        ]);

        qIndices[q] = _QuestionColIndices(
          qTextIdx: qTextIdx,
          choiceAIdx: cAIdx,
          choiceBIdx: cBIdx,
          choiceCIdx: cCIdx,
          choiceDIdx: cDIdx,
          answerIdx: ansIdx,
        );
      }

      final parsed = <_ParsedMaterialRow>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((c) => c.isEmpty)) continue;

        String? error;
        final title = titleIdx < row.length ? row[titleIdx] : '';
        final passage = passageIdx < row.length ? row[passageIdx] : '';

        int grade = _singleGrade;
        if (gradeIdx != -1 && gradeIdx < row.length) {
          final gMatch = RegExp(r'\d+').firstMatch(row[gradeIdx]);
          if (gMatch != null) {
            final gNum = int.tryParse(gMatch.group(0)!);
            if (gNum != null && [4, 5, 6].contains(gNum)) {
              grade = gNum;
            }
          }
        }

        if (title.isEmpty) {
          error = 'Row $i: Missing title.';
        } else if (passage.isEmpty) {
          error = 'Row $i: Missing reading passage.';
        }

        final questions = <Map<String, dynamic>>[];
        for (int q = 1; q <= 5; q++) {
          final cols = qIndices[q]!;
          final qText = cols.qTextIdx != -1 && cols.qTextIdx < row.length
              ? row[cols.qTextIdx]
              : '';
          final cA = cols.choiceAIdx != -1 && cols.choiceAIdx < row.length
              ? row[cols.choiceAIdx]
              : '';
          final cB = cols.choiceBIdx != -1 && cols.choiceBIdx < row.length
              ? row[cols.choiceBIdx]
              : '';
          final cC = cols.choiceCIdx != -1 && cols.choiceCIdx < row.length
              ? row[cols.choiceCIdx]
              : '';
          final cD = cols.choiceDIdx != -1 && cols.choiceDIdx < row.length
              ? row[cols.choiceDIdx]
              : '';
          String ans = cols.answerIdx != -1 && cols.answerIdx < row.length
              ? row[cols.answerIdx].toUpperCase()
              : 'A';

          if (!['A', 'B', 'C', 'D'].contains(ans)) {
            ans = 'A';
          }

          if (error == null) {
            if (qText.isEmpty) {
              error = 'Row $i: Missing question $q text.';
            } else if (cA.isEmpty || cB.isEmpty || cC.isEmpty || cD.isEmpty) {
              error = 'Row $i: Question $q is missing one or more choices.';
            }
          }

          questions.add({
            'questionText': qText,
            'choiceA': cA,
            'choiceB': cB,
            'choiceC': cC,
            'choiceD': cD,
            'correctAnswer': ans,
          });
        }

        parsed.add(_ParsedMaterialRow(
          title: title,
          passage: passage,
          gradeLevel: grade,
          questions: questions,
          error: error,
        ));
      }

      if (!mounted) return;
      setState(() {
        _isProcessingCsv = false;
        _parsedMaterials = parsed;
        if (parsed.isEmpty) {
          _csvError = 'No valid rows found in the CSV file.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingCsv = false;
        _csvError = 'Failed to process CSV file: $e';
      });
    }
  }

  Future<void> _submitImportCsv() async {
    final validMaterials = _parsedMaterials.where((m) => m.isValid).toList();
    if (validMaterials.isEmpty) return;

    setState(() => _isSavingImport = true);

    int successCount = 0;
    String? firstError;

    for (final mat in validMaterials) {
      try {
        await MaterialService.createMaterial(
          title: mat.title,
          passage: mat.passage,
          gradeLevel: mat.gradeLevel,
          questions: mat.questions,
        );
        successCount++;
      } catch (e) {
        firstError ??= e.toString().replaceAll('Exception: ', '');
      }
    }

    if (!mounted) return;
    setState(() => _isSavingImport = false);

    if (successCount > 0) {
      widget.onMaterialAdded();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully imported $successCount reading material${successCount > 1 ? "s" : ""}!',
          ),
        ),
      );
    } else if (firstError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $firstError')),
      );
    }
  }

  Future<void> _submitSingleMaterial() async {
    final title = _titleController.text.trim();
    final passage = _passageController.text.trim();

    if (title.isEmpty || passage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both title and reading passage.'),
        ),
      );
      return;
    }

    for (int i = 0; i < 5; i++) {
      if (_questionControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill text for Question ${i + 1}.')),
        );
        return;
      }
      for (int c = 0; c < 4; c++) {
        if (_choiceControllers[i][c].text.trim().isEmpty) {
          final letter = String.fromCharCode(65 + c);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please fill in Choice $letter for Question ${i + 1}.',
              ),
            ),
          );
          return;
        }
      }
    }

    final questionsPayload = List.generate(5, (i) {
      return {
        'questionText': _questionControllers[i].text.trim(),
        'choiceA': _choiceControllers[i][0].text.trim(),
        'choiceB': _choiceControllers[i][1].text.trim(),
        'choiceC': _choiceControllers[i][2].text.trim(),
        'choiceD': _choiceControllers[i][3].text.trim(),
        'correctAnswer': _correctAnswers[i],
      };
    });

    setState(() => _isSavingSingle = true);

    try {
      await MaterialService.createMaterial(
        title: title,
        passage: passage,
        gradeLevel: _singleGrade,
        questions: questionsPayload,
      );

      if (!mounted) return;
      widget.onMaterialAdded();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading material created successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingSingle = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final validImportCount =
        _parsedMaterials.where((m) => m.isValid).length;
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(size.width * 0.95, 700.0);
    final dialogHeight = math.min(size.height * 0.88, 760.0);

    return Dialog(
      backgroundColor: const Color(0xFFFAF9F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Reading Material',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    size: 18,
                                    color: _selectedTab == 0
                                        ? textPrimary
                                        : textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Single Material',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 0
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: _selectedTab == 0
                                          ? textPrimary
                                          : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file_rounded,
                                    size: 18,
                                    color: _selectedTab == 1
                                        ? textPrimary
                                        : textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Import CSV',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 1
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: _selectedTab == 1
                                          ? textPrimary
                                          : textSecondary,
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

            Expanded(
              child: _selectedTab == 0
                  ? _buildSingleMaterialTab()
                  : _buildImportCsvTab(),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: _selectedTab == 0
                        ? ElevatedButton(
                            onPressed:
                                _isSavingSingle ? null : _submitSingleMaterial,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSavingSingle
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Save Material'),
                          )
                        : ElevatedButton.icon(
                            onPressed: (_isSavingImport || validImportCount == 0)
                                ? null
                                : _submitImportCsv,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: _isSavingImport
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(
                                    'Import ($validImportCount) Materials',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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

  Widget _buildSingleMaterialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          DropdownButtonFormField<int>(
            initialValue: _singleGrade,
            decoration: const InputDecoration(
              labelText: 'Grade Level',
              prefixIcon: Icon(Icons.school_rounded, color: textSecondary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 4, child: Text('Grade 4')),
              DropdownMenuItem(value: 5, child: Text('Grade 5')),
              DropdownMenuItem(value: 6, child: Text('Grade 6')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _singleGrade = val);
            },
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Material Title',
              hintText: 'e.g. The Crow and the Pitcher',
              prefixIcon: Icon(Icons.title_rounded, color: textSecondary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _passageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Reading Passage',
              hintText: 'Enter or paste the full passage text here...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'COMPREHENSION QUESTIONS (5 REQUIRED)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          ...List.generate(5, (qIdx) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Question ${qIdx + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _questionControllers[qIdx],
                    decoration: InputDecoration(
                      labelText: 'Question ${qIdx + 1} Text',
                      isDense: true,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(4, (cIdx) {
                    final letter = String.fromCharCode(65 + cIdx);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        controller: _choiceControllers[qIdx][cIdx],
                        decoration: InputDecoration(
                          labelText: 'Choice $letter',
                          prefixText: '$letter. ',
                          isDense: true,
                          border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _correctAnswers[qIdx],
                    decoration: const InputDecoration(
                      labelText: 'Correct Answer',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('Choice A')),
                      DropdownMenuItem(value: 'B', child: Text('Choice B')),
                      DropdownMenuItem(value: 'C', child: Text('Choice C')),
                      DropdownMenuItem(value: 'D', child: Text('Choice D')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _correctAnswers[qIdx] = val);
                      }
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImportCsvTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: textSecondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Bulk Import Instructions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload a CSV file containing reading materials. Each row should include grade_level, title, passage, and 5 questions with 4 choices (A, B, C, D) and the correct answer.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: textSecondary),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _downloadCsvTemplate,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download CSV Template'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessingCsv ? null : _pickAndProcessCsv,
                icon: const Icon(Icons.upload_file_rounded, size: 20),
                label: Text(
                  _isProcessingCsv
                      ? 'Reading CSV file...'
                      : (_csvFileName == null
                          ? 'Select CSV File'
                          : 'Change CSV File ($_csvFileName)'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_csvError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _csvError!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_parsedMaterials.isNotEmpty) ...[
            Text(
              'PARSED READING MATERIALS (${_parsedMaterials.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _parsedMaterials.length,
              itemBuilder: (context, idx) {
                final mat = _parsedMaterials[idx];
                final isValid = mat.isValid;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isValid ? Colors.white : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isValid
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isValid
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isValid
                              ? Icons.check_rounded
                              : Icons.warning_amber_rounded,
                          color: isValid
                              ? const Color(0xFF10B981)
                              : const Color(0xFFD97706),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mat.title.isNotEmpty ? mat.title : 'Untitled',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isValid)
                              Text(
                                'Grade ${mat.gradeLevel} • ${mat.questions.length} questions • ${mat.passage.split(RegExp(r'\s+')).length} words',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              )
                            else
                              Text(
                                mat.error ?? 'Invalid format',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionColIndices {
  final int qTextIdx;
  final int choiceAIdx;
  final int choiceBIdx;
  final int choiceCIdx;
  final int choiceDIdx;
  final int answerIdx;

  _QuestionColIndices({
    required this.qTextIdx,
    required this.choiceAIdx,
    required this.choiceBIdx,
    required this.choiceCIdx,
    required this.choiceDIdx,
    required this.answerIdx,
  });
}

class _ParsedMaterialRow {
  final String title;
  final String passage;
  final int gradeLevel;
  final List<Map<String, dynamic>> questions;
  final String? error;

  _ParsedMaterialRow({
    required this.title,
    required this.passage,
    required this.gradeLevel,
    required this.questions,
    this.error,
  });

  bool get isValid => error == null;
}
