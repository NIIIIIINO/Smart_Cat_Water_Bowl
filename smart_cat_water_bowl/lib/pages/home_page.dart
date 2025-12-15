import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cat_detail_page.dart';
import 'notifications_page.dart';
import 'live_camera_preview.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isCameraOn = false; // 🔴 กล้องปิดเป็นค่าเริ่มต้น

  @override
  void dispose() {
    // ✅ ปิดกล้องอัตโนมัติเมื่อออกจากหน้า Home
    isCameraOn = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('DEBUG UID = $uid');

    final query = FirebaseFirestore.instance
        .collection('cats')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.transparent,

      // ===== AppBar with PreferredSize =====
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
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
            // ===== Notification Icon =====
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('ownerUid', isEqualTo: uid)
                  .where('seen', isEqualTo: false)
                  .snapshots(),
              builder: (context, snap) {
                final unread = snap.hasData ? snap.data!.docs.length : 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        iconSize: 32, // 🔍 ขยายขนาดไอคอน (default = 24)
                        padding: const EdgeInsets.all(12), // 🖐️ ขยายพื้นที่กด
                        icon: const Icon(Icons.notifications),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          );
                        },
                      ),

                      if (unread > 0)
                        Positioned(
                          right: 6,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // ===== Logout Menu =====
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
      ),

      // ===== Body =====
      body: Column(
        children: [
          // ===== Live Camera Section =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: isCameraOn
                      ? const LiveCameraPreview()
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.videocam_off,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  icon: Icon(isCameraOn ? Icons.stop : Icons.videocam),
                  label: Text(isCameraOn ? 'Close Camera' : 'Open Camera'),
                  onPressed: () {
                    setState(() {
                      isCameraOn = !isCameraOn;
                    });
                  },
                ),
              ],
            ),
          ),

          // ===== Header =====
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Cats',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/info'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Cat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                      0,
                      255,
                      201,
                      232,
                    ), // พื้นหลังปุ่ม
                    foregroundColor: const Color(
                      0xFF5C4033,
                    ), // สีไอคอน/ตัวอักษร
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                        color: Color(0xFF6C9A8B), // ✅ สีขอบ
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== Cats Grid =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No cats yet'));
                }

                final docs = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'Unnamed';
                    final profile = data['profileImage'] as String?;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CatDetailPage(data: data, docId: doc.id),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: profile != null
                                ? NetworkImage(profile)
                                : null,
                            child: profile == null
                                ? const Icon(
                                    Icons.pets,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5C4033),
                            ),
                          ),
                        ],
                      ),
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
