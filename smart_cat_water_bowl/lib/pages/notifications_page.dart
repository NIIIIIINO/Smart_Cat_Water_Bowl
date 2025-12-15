import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('notifications')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          final docs = snap.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? data['message'] ?? 'Notification';
              final message = data['message'] ?? '';
              final seen = data['seen'] ?? false;
              final ts = data['createdAt'];
              final time = ts is Timestamp
                  ? ts.toDate().toLocal().toString()
                  : '';

              return ListTile(
                leading: Icon(
                  seen ? Icons.notifications_none : Icons.notifications_active,
                  color: seen
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                ),
                title: Text(title),
                subtitle: Text(time),
                trailing: seen
                    ? null
                    : const Text('New', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  // mark as seen if not already
                  if (!seen) {
                    FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(doc.id)
                        .update({'seen': true});
                  }
                  // show details
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(title),
                      content: Text(
                        message.isNotEmpty ? message : 'No details',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
