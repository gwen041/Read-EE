import 'package:flutter/material.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final materials = [
      'The Little Boy',
      'The Lost Dog',
      'A Day at School',
    ];

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
                  return Card(
                    child: ListTile(
                      title: Text(materials[index]),
                      trailing: const Icon(Icons.arrow_forward),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('ADD MATERIAL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}