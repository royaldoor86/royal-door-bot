import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../app_theme.dart';
import '../../../../services/firestore_service.dart';

class AdminBotPointsPage extends StatefulWidget {
  const AdminBotPointsPage({Key? key}) : super(key: key);

  @override
  State<AdminBotPointsPage> createState() => _AdminBotPointsPageState();
}

class _AdminBotPointsPageState extends State<AdminBotPointsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = "";

  void _updatePoints(String uid, int currentPoints, bool isAdding, String? tgId, String name) {
    int amount = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1F1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isAdding ? "إضافة نقاط لـ $name" : "خصم نقاط من $name", style: const TextStyle(color: AppTheme.royalGold, fontSize: 16)),
        content: TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "أدخل الكمية...",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.royalGold.withOpacity(0.3))),
          ),
          onChanged: (val) => amount = int.tryParse(val) ?? 0,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
            onPressed: () async {
              if (amount > 0) {
                int newPoints = isAdding ? currentPoints + amount : currentPoints - amount;
                await _firestore.collection('users').doc(uid).update({'botPoints': newPoints});
                
                if (tgId != null) {
                  String msg = isAdding 
                    ? "🎁 قام المسؤول بإضافة $amount نقطة ملكية إلى حسابك!" 
                    : "⚠️ تم خصم $amount نقطة من حسابك من قبل الإدارة.";
                  await _firestoreService.sendBotNotification(tgId, msg);
                }

                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("تأكيد", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1F1C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: const Text('إدارة نقاط التلغرام والتحقق', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "بحث بالاسم، الهاتف، أو الآيدي...",
                  prefixIcon: const Icon(Icons.search, color: AppTheme.royalGold),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').where('telegramId', isNull: false).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
                  
                  var users = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name = data['name']?.toString().toLowerCase() ?? "";
                    String rid = data['royalId']?.toString().toLowerCase() ?? "";
                    String tgPhone = data['telegramPhone']?.toString().toLowerCase() ?? "";
                    String q = _searchQuery.toLowerCase();
                    return name.contains(q) || rid.contains(q) || tgPhone.contains(q);
                  }).toList();

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var data = users[index].data() as Map<String, dynamic>;
                      int points = data['botPoints'] ?? 0;
                      String? tgId = data['telegramId'];
                      String tgPhone = data['telegramPhone'] ?? "لم يشارك الرقم بعد";

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.royalGold.withOpacity(0.1),
                            child: const Icon(Icons.send_rounded, color: Colors.blueAccent, size: 20),
                          ),
                          title: Text(data['name'] ?? 'مستخدم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("🆔 Royal ID: ${data['royalId']}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              Row(
                                children: [
                                  const Icon(Icons.phone_android, color: Colors.greenAccent, size: 12),
                                  const SizedBox(width: 5),
                                  Text("تلغرام: $tgPhone", style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("$points ✨", style: const TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 24), onPressed: () => _updatePoints(users[index].id, points, true, tgId, data['name'])),
                                      IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 24), onPressed: () => _updatePoints(users[index].id, points, false, tgId, data['name'])),
                                    ],
                                  ),
                                ],
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
      ),
    );
  }
}
