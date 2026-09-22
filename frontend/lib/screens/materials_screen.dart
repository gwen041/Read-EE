import 'package:flutter/material.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final List<Map<String, String>> materials = [
    {
      'title': 'The Little Boy',
      'passage':
          'The little boy walked to the school early in the morning.',
    },
    {
      'title': 'The Lost Dog',
      'passage':
          'A little girl looked for her lost dog around the neighborhood.',
    },
    {
      'title': 'A Day at School',
      'passage':
          'The students arrived at school and prepared for their lessons.',
    },
  ];

  void addMaterial() {
    final titleController = TextEditingController();
    final passageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Reading Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
              ],
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
                if (titleController.text.trim().isEmpty ||
                    passageController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  materials.add({
                    'title': titleController.text.trim(),
                    'passage': passageController.text.trim(),
                  });
                });

                Navigator.pop(context);
              },
              child: const Text('ADD'),
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
                      title: Text(material['title']!),
                      subtitle: Text(
                        material['passage']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward),
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