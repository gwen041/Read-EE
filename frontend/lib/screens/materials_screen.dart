import 'package:flutter/material.dart';
import '../models/reading_material.dart';
import '../services/material_service.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<ReadingMaterialItem> _materials = [];
  bool _isLoading = true;
  int? _selectedGradeFilter; // null = All grades, or 4, 5, 6

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await MaterialService.getMaterials(
        gradeLevel: _selectedGradeFilter,
      );
      if (!mounted) return;
      setState(() {
        _materials = fetched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void addMaterial() {
    final titleController = TextEditingController();
    final passageController = TextEditingController();
    int selectedGrade = _selectedGradeFilter ?? 4;
    bool isSaving = false;

    final questionControllers = List.generate(
      5,
      (_) => TextEditingController(),
    );

    final choiceControllers = List.generate(
      5,
      (_) => List.generate(
        4,
        (_) => TextEditingController(),
      ),
    );

    List<String> correctAnswers = List.filled(5, 'A');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Reading Material'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: selectedGrade,
                        decoration: const InputDecoration(
                          labelText: 'Grade Level',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 4, child: Text('Grade 4')),
                          DropdownMenuItem(value: 5, child: Text('Grade 5')),
                          DropdownMenuItem(value: 6, child: Text('Grade 6')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedGrade = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Material Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passageController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Reading Passage',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Comprehension Questions (5 Required)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(5, (questionIndex) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Question ${questionIndex + 1}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller:
                                      questionControllers[questionIndex],
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Question',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(4, (choiceIndex) {
                                  final letter =
                                      String.fromCharCode(65 + choiceIndex);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: TextField(
                                      controller: choiceControllers[
                                          questionIndex][choiceIndex],
                                      decoration: InputDecoration(
                                        labelText: 'Choice $letter',
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  );
                                }),
                                DropdownButtonFormField<String>(
                                  initialValue: correctAnswers[questionIndex],
                                  decoration: const InputDecoration(
                                    labelText: 'Correct Answer',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'A',
                                      child: Text('Choice A'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'B',
                                      child: Text('Choice B'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'C',
                                      child: Text('Choice C'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'D',
                                      child: Text('Choice D'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setDialogState(() {
                                      correctAnswers[questionIndex] = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty ||
                              passageController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a title and reading passage.',
                                ),
                              ),
                            );
                            return;
                          }

                          for (int i = 0; i < 5; i++) {
                            if (questionControllers[i].text.trim().isEmpty) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter text for Question ${i + 1}.',
                                  ),
                                ),
                              );
                              return;
                            }

                            for (int j = 0; j < 4; j++) {
                              if (choiceControllers[i][j].text.trim().isEmpty) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please fill in all 4 choices for Question ${i + 1}.',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }
                          }

                          final questionsPayload = List.generate(5, (i) {
                            return {
                              'questionText':
                                  questionControllers[i].text.trim(),
                              'choiceA': choiceControllers[i][0].text.trim(),
                              'choiceB': choiceControllers[i][1].text.trim(),
                              'choiceC': choiceControllers[i][2].text.trim(),
                              'choiceD': choiceControllers[i][3].text.trim(),
                              'correctAnswer': correctAnswers[i],
                            };
                          });

                          setDialogState(() => isSaving = true);

                          try {
                            await MaterialService.createMaterial(
                              title: titleController.text.trim(),
                              passage: passageController.text.trim(),
                              gradeLevel: selectedGrade,
                              questions: questionsPayload,
                            );

                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            _loadMaterials();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reading material saved successfully!',
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('SAVE MATERIAL'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteMaterial(ReadingMaterialItem material) async {
    try {
      await MaterialService.deleteMaterial(material.id);
      _loadMaterials();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void viewMaterial(ReadingMaterialItem material) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${material.title} (Grade ${material.gradeLevel ?? "-"})',
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reading Passage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(material.passage),
                  const SizedBox(height: 20),
                  const Text(
                    'Comprehension Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...material.questions.map((q) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${q.questionOrder}. ${q.questionText}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('A. ${q.choiceA}'),
                          Text('B. ${q.choiceB}'),
                          Text('C. ${q.choiceC}'),
                          Text('D. ${q.choiceD}'),
                          const SizedBox(height: 4),
                          Text(
                            'Correct Answer: ${q.correctAnswer}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Materials'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reading Materials',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('All Grades'),
                  selected: _selectedGradeFilter == null,
                  onSelected: (_) {
                    setState(() => _selectedGradeFilter = null);
                    _loadMaterials();
                  },
                ),
                for (final grade in [4, 5, 6])
                  ChoiceChip(
                    label: Text('Grade $grade'),
                    selected: _selectedGradeFilter == grade,
                    onSelected: (_) {
                      setState(() => _selectedGradeFilter = grade);
                      _loadMaterials();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _materials.isEmpty
                      ? const Center(
                          child: Text(
                            'No reading materials found for this grade.',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _materials.length,
                          itemBuilder: (context, index) {
                            final material = _materials[index];

                            return Card(
                              child: ListTile(
                                title: Text(material.title),
                                subtitle: Text(
                                  'Grade ${material.gradeLevel ?? "-"} • '
                                  '${material.isBuiltIn ? "Built-in (Phil-IRI)" : "Teacher Created"} • '
                                  '${material.questions.length} questions',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!material.isBuiltIn)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            deleteMaterial(material),
                                      ),
                                    const Icon(Icons.arrow_forward),
                                  ],
                                ),
                                onTap: () {
                                  viewMaterial(material);
                                },
                              ),
                            );
                          },
                        ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: addMaterial,
                icon: const Icon(Icons.add),
                label: const Text('ADD MATERIAL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}