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
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFAF3DD), Color(0xFFF7F6A3)],
            ),
          ),
        ),
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditCatPage(docId: docId, data: data),
                ),
              ).then((result) {
                // if edit or delete happened, pop detail so home will refresh
                if (result == true) Navigator.of(context).pop(true);
              });
            },
          ),
        ],
      ),
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
          Text(
            'Age: ${data['ageText'] ?? '-'}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Weight: ${weight != null ? weight.toStringAsFixed(1) : '-'} kg',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
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
                      ),
                    ),
                  if (recommendedMl == null)
                    const Text(
                      'Weight not available to calculate',
                      style: TextStyle(color: Colors.black54),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Formula: weight(kg) × 50 × age multiplier',
                    style: const TextStyle(color: Colors.black54),
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
          const SizedBox(height: 12),
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
                        for (var m in multipliers)
                          values.add((recommendedMl * m).round());
                      } else {
                        values.addAll([150, 180, 200, 170, 140, 220, 190]);
                      }

                      final maxVal = values
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble();
                      final days = [
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
                                        color: Colors.green.shade700,
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
                                          color: Colors.blue.shade300,
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
