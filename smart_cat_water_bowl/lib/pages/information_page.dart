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
  final ageController = TextEditingController(); // เก็บ ageText เช่น "2 Y 3 M"
  final weightController = TextEditingController();

  // dropdown วัน/เดือน/ปี
  int? _day;
  int? _month;
  int? _year;

  // รูปโปรไฟล์ (1 รูป)
  XFile? _profileImage;

  // รูปหลายรูป (แกลเลอรี่แมว)
  final List<XFile> _picked = [];

  // Gender
  String? _gender; // Male | Female | Unknown

  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    super.dispose();
  }

  // helper: จำนวนวันในเดือนนั้น ๆ (รองรับ leap year)
  int _daysInMonth(int year, int month) {
    final firstDayThisMonth = DateTime(year, month, 1);
    final firstDayNextMonth = DateTime(year, month + 1, 1);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  // คำนวณอายุแบบ "ปี + เดือน" แล้วใส่ลง ageController อัตโนมัติ
  void _updateAgeFromBirthDate() {
    if (_day == null || _month == null || _year == null) return;

    final birthDate = DateTime(_year!, _month!, _day!);
    final today = DateTime.now();

    int totalMonths =
        (today.year - birthDate.year) * 12 + (today.month - birthDate.month);

    // ถ้าวันของวันนี้ยังไม่ถึงวันเกิดในเดือนนี้ ให้ลด 1 เดือน
    if (today.day < birthDate.day) totalMonths--;

    if (totalMonths < 0) totalMonths = 0;

    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;

    String ageText = '';
    if (years > 0) ageText += '$years Y ';
    ageText += '$months M';

    ageController.text = ageText;
  }

  // ดึง "อายุเป็นปี" (เก็บตัวเลขใน Firestore)
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

  // style ของช่องกรอกให้เหมือนหน้า Login
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
      });
    } catch (_) {
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
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถเลือกรูปได้')));
    }
  }

  Future<List<String>> _uploadImages(String catId) async {
    final List<String> urls = [];
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      debugPrint('❌ No user logged in');
      return urls;
    }

    for (var i = 0; i < _picked.length; i++) {
      try {
        final file = File(_picked[i].path);

        final ref = FirebaseStorage.instance.ref().child(
          'cats/$uid/$catId/image_$i.jpg',
        );

        debugPrint('⬆️ Uploading: cats/$uid/$catId/image_$i.jpg');

        final snapshot = await ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        debugPrint('❌ upload image error: $e');
      }
    }
    return urls;
  }

  Future<String?> _uploadProfileImage(String catId) async {
    if (_profileImage == null) return null;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('❌ No user logged in');
      return null;
    }

    try {
      final file = File(_profileImage!.path);

      final ref = FirebaseStorage.instance.ref().child(
        'cats/$uid/$catId/profile.jpg',
      );

      debugPrint('⬆️ Uploading profile image');

      final snapshot = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ upload profile error: $e');
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

    if (_gender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกเพศของแมว')));
      return;
    }

    final birthDate = DateTime(_year!, _month!, _day!);

    _updateAgeFromBirthDate();
    final ageText = ageController.text.trim();

    if (name.isEmpty || weight == null || ageText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกน้ำหนักแมว')));
      return;
    }

    final ageYears = _ageYearsFromBirthDate(birthDate);

    setState(() => _isSaving = true);
    try {
      final ownerUid = FirebaseAuth.instance.currentUser?.uid;

      final docRef = FirebaseFirestore.instance.collection('cats').doc();
      final catId = docRef.id;

      final profileUrl = await _uploadProfileImage(catId);

      List<String> imageUrls = [];
      if (_picked.isNotEmpty) {
        imageUrls = await _uploadImages(catId);
      }

      await docRef.set({
        'name': name,
        'gender': _gender,
        'ageText': ageText,
        'birthDate': Timestamp.fromDate(birthDate),
        'weight': weight,
        'profileImage': profileUrl,
        'images': imageUrls,
        'ownerUid': ownerUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add training task for backend AI: store image URLs and profile for processing
      try {
        await FirebaseFirestore.instance.collection('ai_training_queue').add({
          'catId': catId,
          'ownerUid': ownerUid,
          'images': imageUrls,
          'profileImage': profileUrl,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Failed to queue AI training task: $e');
      }

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

    final safeYear = _year ?? currentYear;
    final safeMonth = _month ?? 1;
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
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Color(0xFFFFC9E8), // ✅ AppBar สีขาว
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // รูปโปรไฟล์แบบวงกลม (กดแล้วเลือก กล้อง/แกลเลอรี่)
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
                        isExpanded: true,
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
                        isExpanded: true,
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
                        isExpanded: true,
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

                // ✅ Gender dropdown (แก้ล้นจอด้วย DropdownMenu)
                DropdownMenu<String>(
                  expandedInsets: EdgeInsets.zero,
                  initialSelection: _gender,
                  onSelected: (v) => setState(() => _gender = v),
                  hintText: 'Gender',
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'Male', label: 'Male'),
                    DropdownMenuEntry(value: 'Female', label: 'Female'),
                    DropdownMenuEntry(value: 'Unknown', label: 'Unknown'),
                  ],
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 17),

                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('Weight (kg)'),
                ),

                const SizedBox(height: 24),

                // Pick Images (กรอบเขียว โปร่งใส)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _pickImages,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(
                        color: Color(0xFF6C9A8B),
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
                        color: Color(0xFF6C9A8B),
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

                // Save
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
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontFamily: 'MontserratAlternates',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
