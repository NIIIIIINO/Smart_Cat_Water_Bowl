import 'package:flutter/material.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();

  final List<String> images = []; // TODO: add image picker

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Cat Information')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Cat Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Pick multiple images
              },
              child: const Text('Upload Images'),
            ),
            const SizedBox(height: 10),
            Text('Images selected: ${images.length}'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // TODO: Save to Firebase
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
