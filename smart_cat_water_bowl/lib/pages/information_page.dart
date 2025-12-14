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
      TextEditingController(); // ✅ จะเก็บ ageText เช่น "2 ปี 3 เดือน"
  final weightController = TextEditingController();

  // ✅ dropdown วัน/เดือน/ปี
  int? _day;
  int? _month;
  int? _year;

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

    // รวมเป็นจำนวน "เดือน" ทั้งหมด
    int totalMonths =
        (today.year - birthDate.year) * 12 + (today.month - birthDate.month);

    // ถ้าวันของวันนี้ยังไม่ถึงวันเกิดในเดือนนี้ ให้ลด 1 เดือน
    if (today.day < birthDate.day) {
      totalMonths--;
    }

    if (totalMonths < 0) totalMonths = 0;

    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;

    // สร้างข้อความ เช่น "2 ปี 3 เดือน" หรือ "5 เดือน"
    String ageText = '';
    if (years > 0) ageText += '$years ปี ';
    ageText += '$months เดือน';

    ageController.text = ageText;
  }

  // ✅ ดึง "อายุเป็นปี" (ใช้เก็บเป็นตัวเลขใน Firestore ถ้าต้องการ)
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

  Future<void> _saveCat() async {
    final name = nameController.text.trim();
    final weight = double.tryParse(weightController.text.trim());

    // ✅ ตรวจ dropdown วันเดือนปี
    if (_day == null || _month == null || _year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือก วัน/เดือน/ปี ให้ครบ')),
      );
      return;
    }

    // ✅ สร้างวันเกิด
    late final DateTime birthDate;
    try {
      birthDate = DateTime(_year!, _month!, _day!);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('วันเดือนปีไม่ถูกต้อง')));
      return;
    }

    // ✅ คำนวณอายุอัตโนมัติ (ถ้ายังไม่คำนวณ ให้คำนวณก่อนเซฟ)
    _updateAgeFromBirthDate();
    final ageText = ageController.text.trim();

    if (name.isEmpty || weight == null || ageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    // ✅ เก็บ age เป็น "ปี" ด้วย (เผื่อ query/filter ง่าย)
    final ageYears = _ageYearsFromBirthDate(birthDate);

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
        'age': ageYears, // ✅ อายุเป็นปี (ตัวเลข)
        'ageText': ageText, // ✅ อายุแบบ "2 ปี 3 เดือน"
        'birthDate': Timestamp.fromDate(birthDate), // ✅ วันเดือนปี
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
    // ✅ ปีให้เลือก (ย้อนหลัง 25 ปี ถึงปีปัจจุบัน)
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(26, (i) => currentYear - i);

    // ✅ เดือน 1-12
    final months = List<int>.generate(12, (i) => i + 1);

    // ✅ วัน: ต้องรู้ปี+เดือนก่อน (กันวันที่เกิน)
    final int safeYear = _year ?? currentYear;
    final int safeMonth = _month ?? 1;
    final maxDay = _daysInMonth(safeYear, safeMonth);
    final days = List<int>.generate(maxDay, (i) => i + 1);

    // ถ้าเลือกวันไว้แล้ว แต่เดือน/ปีเปลี่ยนจนวันเกิน ให้รีเซ็ตวัน
    if (_day != null && _day! > maxDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _day = null);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7F6A3), Color(0xFFFFC9E8)],
            ),
          ),
        ),
        title: const Text('Add Cat Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Cat Name'),
            ),
            const SizedBox(height: 10),

            // ✅ Age Auto (readOnly)
            TextField(
              controller: ageController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Age (Auto: ปี/เดือน)',
              ),
            ),

            const SizedBox(height: 10),

            // ✅ Dropdown วัน/เดือน/ปี (ต่อท้าย Age)
            const Text(
              'Birth Date (Day/Month/Year)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                // Day
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _day,
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      filled: true,
                      fillColor: Colors.white,
                    ),
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
                        _updateAgeFromBirthDate(); // ✅ คำนวณอายุ
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Month
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _month,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      filled: true,
                      fillColor: Colors.white,
                    ),
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
                        _updateAgeFromBirthDate(); // ✅ คำนวณอายุ
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Year
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _year,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      filled: true,
                      fillColor: Colors.white,
                    ),
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
                        _updateAgeFromBirthDate(); // ✅ คำนวณอายุ
                      });
                    },
                  ),
                ),
              ],
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
