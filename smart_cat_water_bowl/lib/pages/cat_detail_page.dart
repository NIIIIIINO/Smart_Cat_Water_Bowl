import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_cat_page.dart';

class CatDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const CatDetailPage({super.key, required this.data, required this.docId});

  @override
  State<CatDetailPage> createState() => _CatDetailPageState();
}

class _CatDetailPageState extends State<CatDetailPage> {
  late Map<String, dynamic> data;

  @override
  void initState() {
    super.initState();
    data = Map<String, dynamic>.from(widget.data);
  }

  Future<void> _reloadCat() async {
    final snap = await FirebaseFirestore.instance
        .collection('cats')
        .doc(widget.docId)
        .get();

    if (!mounted) return;

    if (!snap.exists) {
      // ถ้าโดนลบไปแล้ว
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This cat no longer exists')),
      );
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      data = snap.data() as Map<String, dynamic>;
    });
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCatPage(docId: widget.docId, data: data),
      ),
    );

    // ✅ ถ้า save แล้วกลับมา ให้โหลดข้อมูลใหม่ แต่ “ไม่ pop ออก”
    if (result == true || result == 'updated') {
      await _reloadCat();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updated successfully')));
    }

    // ✅ ถ้าลบแล้ว (ในโค้ดคุณ delete pop(true) อยู่) ก็โหลดแล้วจะ detect ไม่ exists
    // หรือถ้าคุณเปลี่ยนเป็น pop('deleted') ก็รองรับด้วย
    if (result == 'deleted') {
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unnamed';

    final weightVal = data['weight'];
    final weight = weightVal != null
        ? (weightVal is num
              ? weightVal.toDouble()
              : double.tryParse(weightVal.toString()))
        : null;

    final images = (data['images'] as List?)?.cast<String>() ?? [];

    double computeAgeYears() {
      try {
        final t = data['ageText']?.toUpperCase() ?? '';
        final yMatch = RegExp(r'(\d+)\s*Y').firstMatch(t);
        final mMatch = RegExp(r'(\d+)\s*M').firstMatch(t);
        final y = yMatch != null ? int.parse(yMatch.group(1)!) : 0;
        final m = mMatch != null ? int.parse(mMatch.group(1)!) : 0;
        return y + m / 12.0;
      } catch (_) {
        return 0.0;
      }
    }

    final ageYears = computeAgeYears();

    double ageMultiplier(double years) {
      if (years < 1.0) return 1.2; // kittens
      if (years < 8.0) return 1.0; // adult
      if (years < 12.0) return 0.9; // senior
      return 0.85; // very senior
    }

    final multiplier = ageMultiplier(ageYears);
    final recommendedMl = (weight != null)
        ? (weight * 50.0 * multiplier)
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFFFFD6E8),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF5C4033)),
          title: Text(
            name,
            style: const TextStyle(
              fontFamily: 'Lobster',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5C4033),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Edit',
              iconSize: 30,
              padding: const EdgeInsets.all(12),
              icon: const Icon(Icons.edit),
              color: const Color(0xFF5C4033),
              onPressed: _openEdit, // ✅ ใช้ฟังก์ชันใหม่
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ รูปแมวแบบวงกลม (เลื่อนได้หลายรูป)
          if (images.isNotEmpty)
            SizedBox(
              height: 260,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, idx) {
                  return Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          images[idx],
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Container(
                              width: 220,
                              height: 220,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.pets,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Center(
              child: CircleAvatar(
                radius: 90,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: $name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Age: ${data['ageText'] ?? '-'}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Weight: ${weight != null ? weight.toStringAsFixed(1) : '-'} kg',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Card(
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended daily water',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (recommendedMl != null)
                    Text(
                      '${recommendedMl.toStringAsFixed(0)} ml/day',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 219, 113, 113),
                      ),
                    )
                  else
                    const Text(
                      'Weight not available to calculate',
                      style: TextStyle(color: Colors.black54),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Formula: weight(kg) × 50 × age multiplier',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Age multiplier: ${multiplier.toStringAsFixed(2)} (based on ${ageYears.toStringAsFixed(2)} years)',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly intake (mock)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final List<double> multipliers = [
                        0.7,
                        0.9,
                        1.0,
                        0.85,
                        0.6,
                        1.1,
                        0.95,
                      ];

                      final List<int> values = [];
                      if (recommendedMl != null) {
                        for (var m in multipliers) {
                          values.add((recommendedMl * m).round());
                        }
                      } else {
                        values.addAll([150, 180, 200, 170, 140, 220, 190]);
                      }

                      final maxVal = values
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble();

                      final days = const [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];

                      return SizedBox(
                        height: 160,
                        child: Stack(
                          children: [
                            if (recommendedMl != null)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 16 + (1 - (recommendedMl / maxVal)) * 80,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(values.length, (i) {
                                  final h = maxVal > 0
                                      ? (values[i] / maxVal) * 100.0
                                      : 0.0;

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: h + 20,
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            255,
                                            134,
                                            195,
                                            245,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6.0,
                                          ),
                                          child: Text(
                                            values[i].toString(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        days[i],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
