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
  final ageController =
      TextEditingController(); // ✅ เก็บ ageText เช่น "2 ปี 3 เดือน"
  final weightController = TextEditingController();

  // ✅ dropdown วัน/เดือน/ปี
  int? _day;
  int? _month;
  int? _year;

  // ✅ รูปโปรไฟล์ (1 รูป)
  XFile? _profileImage;

  // ✅ รูปหลายรูป (แกลเลอรี่แมว)
  final List<XFile> _picked = [];

  // ✅ Gender dropdown
  String? _gender; // 'Male' | 'Female' | 'Unknown'

  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    super.dispose();
  }

  // ✅ helper: จำนวนวันในเดือนนั้น ๆ (รองรับ leap year)
  int _daysInMonth(int year, int month) {
    final firstDayThisMonth = DateTime(year, month, 1);
    final firstDayNextMonth = DateTime(year, month + 1, 1);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  // ✅ คำนวณอายุแบบ "ปี + เดือน" แล้วใส่ลง ageController อัตโนมัติ
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

    ageController.text = ageText;
  }

  // ✅ ดึง "อายุเป็นปี" (เก็บตัวเลขใน Firestore)
  int _ageYearsFromBirthDate(DateTime birthDate) {
    final today = DateTime.now();
    int years = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      years--;
    }
    if (years < 0) years = 0;
    return years;
  }

  // ✅ style ของช่องกรอกให้เหมือนหน้า Login
  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ================== PROFILE IMAGE ==================
  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final XFile? img = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (img == null) return;

      setState(() {
        _profileImage = img;

        // (ออปชัน) ถ้ายังไม่มีรูปใน list ให้ใส่รูปโปรไฟล์เป็นรูปแรก
        if (_picked.isEmpty) _picked.add(img);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเลือกรูปโปรไฟล์ได้')),
      );
    }
  }

  void _showPickProfileSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('เลือกจากแกลเลอรี่'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfileImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('ถ่ายรูปด้วยกล้อง'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfileImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================== MULTI IMAGES ==================
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
        debugPrint('upload image error: $e');
      }
    }
    return urls;
  }

  Future<String?> _uploadProfileImage(String catId) async {
    if (_profileImage == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'unknown';

    try {
      final file = File(_profileImage!.path);
      final ref = FirebaseStorage.instance.ref().child(
        'cats/$uid/$catId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final snapshot = await ref.putFile(file).whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('upload profile error: $e');
      return null;
    }
  }

  Future<void> _saveCat() async {
    final name = nameController.text.trim();
    final weight = double.tryParse(weightController.text.trim());

    if (_day == null || _month == null || _year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือก วัน/เดือน/ปี ให้ครบ')),
      );
      return;
    }

    // ✅ เพิ่ม validation gender
    if (_gender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกเพศของแมว')));
      return;
    }

    late final DateTime birthDate;
    try {
      birthDate = DateTime(_year!, _month!, _day!);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('วันเดือนปีไม่ถูกต้อง')));
      return;
    }

    _updateAgeFromBirthDate();
    final ageText = ageController.text.trim();

    if (name.isEmpty || weight == null || ageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    final ageYears = _ageYearsFromBirthDate(birthDate);

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final ownerUid = user?.uid;

      final docRef = FirebaseFirestore.instance.collection('cats').doc();
      final catId = docRef.id;

      final profileUrl = await _uploadProfileImage(catId);

      List<String> imageUrls = [];
      if (_picked.isNotEmpty) {
        imageUrls = await _uploadImages(catId);
      }

      await docRef.set({
        'name': name,
        'gender': _gender, // ✅ เพิ่ม gender
        'age': ageYears,
        'ageText': ageText,
        'birthDate': Timestamp.fromDate(birthDate),
        'weight': weight,
        'profileImage': profileUrl,
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
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(26, (i) => currentYear - i);
    final months = List<int>.generate(12, (i) => i + 1);

    final int safeYear = _year ?? currentYear;
    final int safeMonth = _month ?? 1;
    final maxDay = _daysInMonth(safeYear, safeMonth);
    final days = List<int>.generate(maxDay, (i) => i + 1);

    if (_day != null && _day! > maxDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _day = null);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70), // 👈 ปรับความสูงตรงนี้
        child: AppBar(
          backgroundColor: const Color(0xFFFFC9E8),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Add Cat Information',
            style: TextStyle(
              fontFamily: 'Lobster',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5C4033),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _showPickProfileSheet,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: const Color(0xFFEFEFEF),
                            backgroundImage: _profileImage != null
                                ? FileImage(File(_profileImage!.path))
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.pets,
                                    size: 42,
                                    color: Color(0xFF6C9A8B),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C9A8B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),

                  TextField(
                    controller: nameController,
                    decoration: _fieldDecoration('Cat Name'),
                  ),
                  const SizedBox(height: 17),

                  TextField(
                    controller: ageController,
                    readOnly: true,
                    decoration: _fieldDecoration('Age (Auto: Y/M)'),
                  ),
                  const SizedBox(height: 17),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Birth Date (Day/Month/Year)',
                      style: TextStyle(
                        fontFamily: 'MontserratAlternates',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5C4033),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _day,
                          decoration: _fieldDecoration('Day'),
                          items: days
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _day = v;
                              _updateAgeFromBirthDate();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _month,
                          decoration: _fieldDecoration('Month'),
                          items: months
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _month = v;
                              _updateAgeFromBirthDate();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _year,
                          decoration: _fieldDecoration('Year'),
                          items: years
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(y.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _year = v;
                              _updateAgeFromBirthDate();
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  // ✅ Gender dropdown (วาง "บนช่อง weight")
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: _fieldDecoration('Gender'),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(
                        value: 'Unknown',
                        child: Text('Unknown'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),

                  const SizedBox(height: 17),

                  // ===== Weight =====
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('Weight (kg)'),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _pickImages,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent, // ✅ โปร่งใส
                        side: const BorderSide(
                          color: Color(0xFF6C9A8B), // ✅ กรอบสีเขียว
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: const Text(
                        'Pick Images',
                        style: TextStyle(
                          fontFamily: 'MontserratAlternates',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 1.2,
                          color: Color(
                            0xFF6C9A8B,
                          ), // ✅ ตัวหนังสือสีเขียว (ให้เข้ากับกรอบ)
                        ),
                      ),
                    ),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveCat,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF6C9A8B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'MontserratAlternates',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 25,
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
          ),
        ),
      ),
    );
  }
}
