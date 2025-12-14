import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();

  final List<XFile> _picked = [];
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? imgs = await _picker.pickMultiImage(imageQuality: 80);
      if (imgs == null) return;
      setState(() => _picked.addAll(imgs));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถเลือกรูปได้')));
    }
  }

  Future<List<String>> _uploadImages(String catId) async {
    final List<String> urls = [];
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'unknown';

    for (var i = 0; i < _picked.length; i++) {
      try {
        final file = File(_picked[i].path);
        final ref = FirebaseStorage.instance.ref().child(
          'cats/$uid/$catId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        // log and continue with other uploads
        // we don't fail whole save for one bad image
        debugPrint('upload image error: $e');
      }
    }
    return urls;
  }

  Future<void> _saveCat() async {
    final name = nameController.text.trim();
    final age = int.tryParse(ageController.text.trim());
    final weight = double.tryParse(weightController.text.trim());

    if (name.isEmpty || age == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final ownerUid = user?.uid;

      final docRef = FirebaseFirestore.instance.collection('cats').doc();
      final catId = docRef.id;

      List<String> imageUrls = [];
      if (_picked.isNotEmpty) {
        imageUrls = await _uploadImages(catId);
      }

      await docRef.set({
        'name': name,
        'age': age,
        'weight': weight,
        'images': imageUrls,
        'ownerUid': ownerUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
              onPressed: _pickImages,
              child: const Text('Pick Images'),
            ),
            const SizedBox(height: 12),
            _picked.isEmpty
                ? const Text('No images selected')
                : SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _picked.length,
                      itemBuilder: (context, idx) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_picked[idx].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _picked.removeAt(idx));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCat,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
