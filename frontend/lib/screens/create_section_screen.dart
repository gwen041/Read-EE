import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class CreateSectionScreen extends StatefulWidget {
  final List<String> selectedGrades;

  const CreateSectionScreen({
    super.key,
    required this.selectedGrades,
  });

  @override
  State<CreateSectionScreen> createState() => _CreateSectionScreenState();
}

class _CreateSectionScreenState extends State<CreateSectionScreen> {
  final Map<String, List<String>> sections = {};

  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();

    for (final grade in widget.selectedGrades) {
      sections[grade] = [];
      controllers[grade] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void addSection(String grade) {
    final controller = controllers[grade]!;
    final sectionName = controller.text.trim();

    if (sectionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a section name.'),
        ),
      );
      return;
    }

    if (sections[grade]!.contains(sectionName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That section already exists.'),
        ),
      );
      return;
    }

    setState(() {
      sections[grade]!.add(sectionName);
      controller.clear();
    });
  }

  void finishSetup() {
    final hasSections = sections.values.any(
      (gradeSections) => gradeSections.isNotEmpty,
    );

    if (!hasSections) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create at least one section.'),
        ),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sections'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Your Sections',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Create the sections you handle for each grade level.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: ListView(
                children: [
                  for (final grade in widget.selectedGrades) ...[
                    Text(
                      grade,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers[grade],
                            decoration: const InputDecoration(
                              labelText: 'Section Name',
                              hintText: 'e.g. Narra',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          onPressed: () => addSection(grade),
                          child: const Text('ADD'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (sections[grade]!.isEmpty)
                      const Text(
                        'No sections added yet.',
                        style: TextStyle(color: Colors.grey),
                      ),

                    for (final section in sections[grade]!)
                      ListTile(
                        leading: const Icon(Icons.class_),
                        title: Text(section),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              sections[grade]!.remove(section);
                            });
                          },
                        ),
                      ),

                    const SizedBox(height: 25),
                  ],
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: finishSetup,
                child: const Text('FINISH SETUP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}