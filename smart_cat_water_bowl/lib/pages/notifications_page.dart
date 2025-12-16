import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const _appBarColor = Color(0xFFFFC9E8);
  static const _titleColor = Color(0xFF5C4033);
  static const _green = Color(0xFF6C9A8B);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // ✅ stream ต้องประกาศก่อน (ถ้า uid null ก็ไม่ต้องใช้)
    final stream = uid == null
        ? const Stream<QuerySnapshot>.empty()
        : FirebaseFirestore.instance
              .collection('notifications')
              .where('ownerUid', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots();

    return Scaffold(
      // ✅ สำคัญ: ให้พื้นหลังโปร่งใสเพื่อโชว์ gradient จาก main.dart
      backgroundColor: Colors.transparent,

      // ✅ AppBar สีเดียวกับหน้า info + ปรับความสูงได้
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Color(0xFFFFC9E8),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Notifications',
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
        child: uid == null
            ? const Center(
                child: Text(
                  'Not signed in',
                  style: TextStyle(
                    fontFamily: 'MontserratAlternates',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C4033),
                  ),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(
                          fontFamily: 'MontserratAlternates',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C4033),
                        ),
                      ),
                    );
                  }

                  final docs = snap.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final title =
                          (data['title'] ?? data['message'] ?? 'Notification')
                              .toString();
                      final message = (data['message'] ?? '').toString();
                      final seen = (data['seen'] ?? false) as bool;

                      final ts = data['createdAt'];
                      final time = ts is Timestamp
                          ? ts.toDate().toLocal().toString()
                          : '';

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.92,
                          ), // ✅ อ่านง่ายบนพื้นหลัง
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: Icon(
                            seen
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: seen ? Colors.grey : _green,
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'MontserratAlternates',
                              fontWeight: seen
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: Color(0xFF5C4033),
                            ),
                          ),
                          subtitle: Text(
                            time,
                            style: const TextStyle(
                              fontFamily: 'MontserratAlternates',
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: seen
                              ? null
                              : const Text(
                                  'New',
                                  style: TextStyle(
                                    fontFamily: 'MontserratAlternates',
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                          onTap: () async {
                            // ✅ mark as seen
                            if (!seen) {
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(doc.id)
                                  .update({'seen': true});
                            }

                            if (!context.mounted) return;

                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontFamily: 'MontserratAlternates',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Text(
                                  message.isNotEmpty ? message : 'No details',
                                  style: const TextStyle(
                                    fontFamily: 'MontserratAlternates',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text(
                                      'Close',
                                      style: TextStyle(
                                        fontFamily: 'MontserratAlternates',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                // create a mock notification: find one of the user's cats (if any)
                try {
                  final q = await FirebaseFirestore.instance
                      .collection('cats')
                      .where('ownerUid', isEqualTo: uid)
                      .limit(1)
                      .get();

                  String catName = 'Your cat';
                  if (q.docs.isNotEmpty) {
                    final d = q.docs.first.data();
                    catName = (d['name'] ?? 'Your cat').toString();
                  }

                  final now = DateTime.now();
                  final title = '$catName drank water';
                  final message =
                      '$catName drank water at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}.';

                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .add({
                        'ownerUid': uid,
                        'title': title,
                        'message': message,
                        'seen': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification created')),
                  );

                  // show details immediately
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'MontserratAlternates',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        message,
                        style: const TextStyle(
                          fontFamily: 'MontserratAlternates',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create notification: $e'),
                      ),
                    );
                }
              },
              label: const Text('Add Noti'),
              icon: const Icon(Icons.add_alert),
            ),
    );
  }
}
