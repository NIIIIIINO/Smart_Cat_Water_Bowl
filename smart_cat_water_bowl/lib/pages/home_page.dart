import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'cat_detail_page.dart';
import 'notifications_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    print('DEBUG UID = $uid');
    final query = FirebaseFirestore.instance
        .collection('cats')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7F6A3), Color(0xFFFAF3DD)],
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'MeowFlow',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C4033),
          ),
        ),
        actions: [
          // Notifications button with unread count badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('ownerUid', isEqualTo: uid)
                .where('seen', isEqualTo: false)
                .snapshots(),
            builder: (context, snap) {
              final unread = (snap.hasData) ? snap.data!.docs.length : 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 6,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              unread > 99 ? '99+' : unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm'),
                    content: const Text('Do you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/');
                }
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Cats',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/info'),
                  child: const Text('Add Cat Info'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query,
              builder: (context, snapshot) {
                print('--- STREAM BUILDER ---');
                print('connectionState = ${snapshot.connectionState}');
                print('hasData = ${snapshot.hasData}');
                print('doc count = ${snapshot.data?.docs.length}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No cats yet'));
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unnamed';
                    final images =
                        (data['images'] as List?)?.cast<String>() ?? [];
                    final thumb = images.isNotEmpty ? images.first : null;
                    return ListTile(
                      leading: thumb != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                thumb,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.pets, color: Colors.grey),
                            ),
                      title: Text(name),
                      subtitle: images.isNotEmpty
                          ? Text('${images.length} image(s)')
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CatDetailPage(data: data, docId: doc.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
