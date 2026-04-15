import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomThemeShopSheet extends StatefulWidget {
  final String roomId;
  const RoomThemeShopSheet({super.key, required this.roomId});

  @override
  State<RoomThemeShopSheet> createState() => _RoomThemeShopSheetState();
}

class _RoomThemeShopSheetState extends State<RoomThemeShopSheet> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Text('خزانة الثيمات الملكية 🎨', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('room_themes').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('لا توجد ثيمات متاحة حالياً', style: TextStyle(color: Colors.white54)));

                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String imageUrl = data['imageUrl'] ?? '';
                    final String name = data['name'] ?? 'ثيم رويال';
                    final int price = data['price'] ?? 0;

                    return GestureDetector(
                      onTap: () => _applyTheme(imageUrl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.amber.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: imageUrl.endsWith('.gif') 
                                  ? Image.network(imageUrl, fit: BoxFit.cover)
                                  : Image.network(imageUrl, fit: BoxFit.cover),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                  const SizedBox(height: 4),
                                  Text('$price 🪙', style: const TextStyle(color: Colors.amber, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Future<void> _applyTheme(String url) async {
    // هنا نقوم بتحديث خلفية الغرفة في Firestore
    try {
      await _db.collection('rooms').doc(widget.roomId).update({
        'backgroundImage': url,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تطبيق الثيم بنجاح ✅')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في تطبيق الثيم ❌')));
    }
  }
}
