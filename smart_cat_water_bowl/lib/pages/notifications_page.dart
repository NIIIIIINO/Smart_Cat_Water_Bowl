import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const _green = Color(0xFF6C9A8B);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final stream = uid == null
        ? const Stream<QuerySnapshot>.empty()
        : FirebaseFirestore.instance
              .collection('notifications')
              .where('ownerUid', isEqualTo: uid)
              .snapshots();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFFFFC9E8),
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
            ? const Center(child: Text('Not signed in'))
            : StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(child: Text('No notifications'));
                  }

                  // ✅ sort ใน app แทน orderBy
                  final docs = [...snap.data!.docs];
                  docs.sort((a, b) {
                    final ta =
                        (a['createdAt'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0;
                    final tb =
                        (b['createdAt'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0;
                    return tb.compareTo(ta);
                  });

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final title =
                          data['title'] ??
                          data['message'] ??
                          data['text'] ??
                          'Notification';

                      final message =
                          data['message'] ??
                          data['body'] ??
                          data['detail'] ??
                          '';

                      final seen = data['seen'] == true;

                      final ts = data['createdAt'];
                      final time = ts is Timestamp
                          ? ts.toDate().toLocal().toString()
                          : '';

                      // ✅ เลือก icon ตาม type จาก cloud
                      final type = data['type'];
                      IconData icon = Icons.notifications;

                      if (type == 'drink_detected') {
                        icon = Icons.local_drink;
                      } else if (type == 'no_drink_today') {
                        icon = Icons.warning_amber;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: Icon(
                            icon,
                            color: seen ? Colors.grey : _green,
                          ),
                          title: Text(
                            title.toString(),
                            style: TextStyle(
                              fontWeight: seen
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(time),
                          trailing: seen
                              ? null
                              : const Text(
                                  'New',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                          onTap: () async {
                            try {
                              if (!seen) {
                                await doc.reference.update({'seen': true});
                              }
                            } catch (_) {}

                            if (!context.mounted) return;

                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(title.toString()),
                                content: Text(
                                  message.toString().isEmpty
                                      ? 'No details'
                                      : message.toString(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
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
    );
  }
}
