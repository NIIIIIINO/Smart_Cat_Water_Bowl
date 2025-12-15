import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  // ✅ ธีมสีเดียวกับหน้าที่แล้ว
  static const _bgTop = Color(0xFFFAF3DD);
  static const _bgBottom = Color(0xFFF7F6A3);
  static const _textBrown = Color(0xFF5C4033);

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _nameCtrl = TextEditingController(text: d['name'] ?? '');
    _ageTextCtrl = TextEditingController(text: d['ageText'] ?? '');
    _weightCtrl = TextEditingController(text: d['weight']?.toString() ?? '');
    _gender = d['gender'] as String?;

    // initialize birth date if present
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
  }

  // helper: days in month
  int _daysInMonth(int year, int month) {
    final firstDayThisMonth = DateTime(year, month, 1);
    final firstDayNextMonth = DateTime(year, month + 1, 1);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  // update ageText from birth fields
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
    final weight = double.tryParse(_weightCtrl.text.trim());

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
      await ref.update({
        'name': name,
        'ageText': ageText,
        'birthDate': Timestamp.fromDate(birthDate),
        'weight': weight,
        'gender': _gender,
      });
      if (mounted) Navigator.of(context).pop(true);
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
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      // ✅ AppBar สีเหมือนหน้าที่แล้ว
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textBrown),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgBottom],
            ),
          ),
        ),
        title: const Text(
          'Edit Cat',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: _textBrown,
            // fontFamily: 'MontserratAlternates',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            onPressed: _saving ? null : _delete,
          ),
        ],
      ),

      // ✅ พื้นหลัง body สีเหมือนหน้าที่แล้ว
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
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

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
