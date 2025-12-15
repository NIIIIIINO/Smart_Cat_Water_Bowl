import 'package:flutter/material.dart';
import 'edit_cat_page.dart';

class CatDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const CatDetailPage({super.key, required this.data, required this.docId});

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
      // Use only ageText (e.g. '2 Y 3 M' or '3 M') to compute years
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

    double ageYears = computeAgeYears();

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
          backgroundColor: const Color(0xFFFFD6E8), // ชมพูพาสเทล
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
              icon: const Icon(Icons.edit),
              color: const Color(0xFF5C4033),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditCatPage(docId: docId, data: data),
                  ),
                ).then((result) {
                  if (result == true) Navigator.of(context).pop(true);
                });
              },
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
            // ✅ กรณีไม่มีรูป ก็ให้เป็นวงกลมเหมือนกัน
            Center(
              child: CircleAvatar(
                radius: 90,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
            ), // ✅ ย่อหน้าเท่ากับใน Card
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
          // Weekly intake mockup chart
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

          //const SizedBox(height: 16),
          //Text(
          // 'Document ID: $docId',
          //style: const TextStyle(fontSize: 12, color: Colors.grey),
          //),
        ],
      ),
    );
  }
}
