import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditCatPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditCatPage({super.key, required this.docId, required this.data});

  @override
  State<EditCatPage> createState() => _EditCatPageState();
}

class _EditCatPageState extends State<EditCatPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageTextCtrl;
  late TextEditingController _weightCtrl;
  String? _gender;
  int? _day;
  int? _month;
  int? _year;
  bool _saving = false;
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _nameCtrl = TextEditingController(text: d['name'] ?? '');
    _ageTextCtrl = TextEditingController(text: d['ageText'] ?? '');
    _weightCtrl = TextEditingController(text: d['weight']?.toString() ?? '');
    _gender = d['gender'] as String?;

    final bd = d['birthDate'];
    DateTime? birth;
    if (bd is Timestamp) {
      birth = bd.toDate();
    } else if (bd is DateTime) {
      birth = bd;
    }

    if (birth != null) {
      _day = birth.day;
      _month = birth.month;
      _year = birth.year;
      _updateAgeFromBirthDate();
    }

    // keep existing profile in state? we only store a local picked file
    // existing remote profile url is in widget.data['profileImage']
  }

  int _daysInMonth(int year, int month) {
    final firstDayThisMonth = DateTime(year, month, 1);
    final firstDayNextMonth = DateTime(year, month + 1, 1);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  void _updateAgeFromBirthDate() {
    if (_day == null || _month == null || _year == null) return;

    final birthDate = DateTime(_year!, _month!, _day!);
    final today = DateTime.now();

    int totalMonths =
        (today.year - birthDate.year) * 12 + (today.month - birthDate.month);
    if (today.day < birthDate.day) totalMonths--;
    if (totalMonths < 0) totalMonths = 0;

    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;

    String ageText = '';
    if (years > 0) ageText += '$years Y ';
    ageText += '$months M';

    _ageTextCtrl.text = ageText;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageTextCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final ageText = _ageTextCtrl.text.trim();

    // ถ้าไม่กรอกน้ำหนัก ให้เก็บเป็น null
    final weightRaw = _weightCtrl.text.trim();
    final weight = weightRaw.isEmpty ? null : double.tryParse(weightRaw);

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter name')));
      return;
    }

    if (_day == null || _month == null || _year == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select birth date')));
      return;
    }

    final birthDate = DateTime(_year!, _month!, _day!);

    setState(() => _saving = true);

    try {
      final ref = FirebaseFirestore.instance
          .collection('cats')
          .doc(widget.docId);

      String? profileUrl;
      if (_profileImage != null) {
        profileUrl = await _uploadProfileImage(widget.docId);
      }

      await ref.update({
        'name': name,
        'ageText': ageText,
        'birthDate': Timestamp.fromDate(birthDate),
        'weight': weight,
        'gender': _gender,
        if (profileUrl != null) 'profileImage': profileUrl,
      });

      // ✅ กลับไปหน้า CatDetailPage พร้อมส่งผลว่า "updated"
      Navigator.pop(context, 'updated');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cat'),
        content: const Text(
          'Are you sure you want to delete this cat? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);

    try {
      final ref = FirebaseFirestore.instance
          .collection('cats')
          .doc(widget.docId);

      await ref.delete();

      // ✅ บอก CatDetailPage ว่าลบแล้ว
      Navigator.pop(context, 'deleted');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? img = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (img == null) return;
      setState(() => _profileImage = img);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot pick profile image')),
      );
    }
  }

  Future<String?> _uploadProfileImage(String catId) async {
    if (_profileImage == null) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    try {
      final file = File(_profileImage!.path);
      final ref = FirebaseStorage.instance.ref().child(
        'cats/$uid/$catId/profile.jpg',
      );
      final snapshot = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('upload profile failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFFFFD6E8),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF5C4033)),
          title: const Text(
            'Edit Cat',
            style: TextStyle(
              fontFamily: 'Lobster',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5C4033),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              iconSize: 30,
              padding: const EdgeInsets.all(12),
              onPressed: _saving ? null : _delete,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 6),
                color: Colors.black.withOpacity(0.10),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              // Profile image preview + change
              GestureDetector(
                onTap: _pickProfileImage,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImage != null
                          ? FileImage(File(_profileImage!.path))
                          : (widget.data['profileImage'] != null
                                ? NetworkImage(widget.data['profileImage'])
                                      as ImageProvider
                                : null),
                      child:
                          (_profileImage == null &&
                              widget.data['profileImage'] == null)
                          ? const Icon(Icons.pets, size: 36, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    const Text('Tap to change profile image'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ageTextCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Age (Auto: Y/M)'),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Birth Date (Day/Month/Year)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final currentYear = DateTime.now().year;
                  final years = List<int>.generate(26, (i) => currentYear - i);
                  final months = List<int>.generate(12, (i) => i + 1);

                  final safeYear = _year ?? currentYear;
                  final safeMonth = _month ?? 1;
                  final maxDay = _daysInMonth(safeYear, safeMonth);
                  final days = List<int>.generate(maxDay, (i) => i + 1);

                  if (_day != null && _day! > maxDay) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _day = null);
                    });
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _day,
                          decoration: const InputDecoration(labelText: 'Day'),
                          items: days
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _day = v;
                            _updateAgeFromBirthDate();
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _month,
                          decoration: const InputDecoration(labelText: 'Month'),
                          items: months
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _month = v;
                            _updateAgeFromBirthDate();
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: _year,
                          decoration: const InputDecoration(labelText: 'Year'),
                          items: years
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(y.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _year = v;
                            _updateAgeFromBirthDate();
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _weightCtrl,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB1CCBB),
                    foregroundColor: const Color(0xFF5C4033),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _saving ? 'Saving...' : 'Save',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'MontserratAlternates',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
