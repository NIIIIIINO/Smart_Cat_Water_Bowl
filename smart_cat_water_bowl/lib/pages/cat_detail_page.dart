import 'package:flutter/material.dart';

class CatDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const CatDetailPage({super.key, required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unnamed';
    final age = data['age']?.toString() ?? '-';
    final weight = data['weight']?.toString() ?? '-';
    final images = (data['images'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, idx) =>
                    Image.network(images[idx], fit: BoxFit.cover),
              ),
            )
          else
            Container(
              height: 200,
              color: Colors.grey[200],
              child: const Icon(Icons.pets, size: 80, color: Colors.grey),
            ),

          const SizedBox(height: 16),
          Text(
            'Name: $name',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('Age: $age', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Weight: $weight kg', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Text(
            'Document ID: $docId',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
