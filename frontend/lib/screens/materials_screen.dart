import 'package:flutter/material.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final List<Map<String, dynamic>> materials = [
    {
      'title': 'The Little Boy',
      'passage':
          'The little boy walked to the school early in the morning.',
      'questions': [],
    },
    {
      'title': 'The Lost Dog',
      'passage':
          'A little girl looked for her lost dog around the neighborhood.',
      'questions': [],
    },
    {
      'title': 'A Day at School',
      'passage':
          'The students arrived at school and prepared for their lessons.',
      'questions': [],
    },
  ];

  void addMaterial() {
    final titleController = TextEditingController();
    final passageController = TextEditingController();

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
      builder: (context) {
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
                        'Comprehension Questions',
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
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
                                  initialValue:
                                      correctAnswers[questionIndex],
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
                                      correctAnswers[questionIndex] =
                                          value!;
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CANCEL'),
                ),

                ElevatedButton(
                  onPressed: () {
                    // Validate title and passage.
                    if (titleController.text.trim().isEmpty ||
                        passageController.text.trim().isEmpty) {
                      return;
                    }

                    // Validate all 5 questions.
                    for (int i = 0; i < 5; i++) {
                      if (questionControllers[i].text.trim().isEmpty) {
                        return;
                      }

                      // Validate all 4 choices.
                      for (int j = 0; j < 4; j++) {
                        if (choiceControllers[i][j]
                            .text
                            .trim()
                            .isEmpty) {
                          return;
                        }
                      }
                    }

                    final questions = List.generate(5, (i) {
                      return {
                        'question':
                            questionControllers[i].text.trim(),
                        'choices': [
                          choiceControllers[i][0].text.trim(),
                          choiceControllers[i][1].text.trim(),
                          choiceControllers[i][2].text.trim(),
                          choiceControllers[i][3].text.trim(),
                        ],
                        'correctAnswer': correctAnswers[i],
                      };
                    });

                    setState(() {
                      materials.add({
                        'title': titleController.text.trim(),
                        'passage': passageController.text.trim(),
                        'questions': questions,
                      });
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('SAVE MATERIAL'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void viewMaterial(int index) {
    final material = materials[index];
    final questions = material['questions'] as List;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(material['title']),
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

                  Text(material['passage']),

                  const SizedBox(height: 20),

                  const Text(
                    'Comprehension Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...questions.asMap().entries.map((entry) {
                    final question = entry.value;

                    final choices =
                        question['choices'] as List;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ${question['question']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text('A. ${choices[0]}'),
                          Text('B. ${choices[1]}'),
                          Text('C. ${choices[2]}'),
                          Text('D. ${choices[3]}'),

                          const SizedBox(height: 4),

                          Text(
                            'Correct Answer: ${question['correctAnswer']}',
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

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: materials.length,
                itemBuilder: (context, index) {
                  final material = materials[index];

                  return Card(
                    child: ListTile(
                      title: Text(material['title']),
                      subtitle: const Text(
                        '5 comprehension questions',
                      ),
                      trailing:
                          const Icon(Icons.arrow_forward),
                      onTap: () {
                        viewMaterial(index);
                      },
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
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