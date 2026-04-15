import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../app_theme.dart';

class FamilyRequestsPage extends StatefulWidget {
  final String familyId;
  const FamilyRequestsPage({super.key, required this.familyId});

  @override
  State<FamilyRequestsPage> createState() => _FamilyRequestsPageState();
}

class _FamilyRequestsPageState extends State<FamilyRequestsPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلبات الانضمام'),
          backgroundColor: const Color(0xFF1A050E),
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3D0B16), Color(0xFF1A050E)])),
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('families').doc(widget.familyId).collection('requests').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد طلبات معلقة', style: TextStyle(color: Colors.white24)));
              
              final requests = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index].data() as Map<String, dynamic>;
                  final String uid = req['uid'];
                  
                  return AppTheme.glassContainer(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    opacity: 0.05,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (req['profilePic'] != null && req['profilePic']!.isNotEmpty) 
                          ? NetworkImage(req['profilePic']) 
                          : null,
                      ),
                      title: Text(req['name'] ?? 'مستخدم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('ليفل ${req['level'] ?? 1}', style: const TextStyle(color: Colors.white54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () async {
                              try {
                                await _familyService.acceptJoinRequest(widget.familyId, uid);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: () => _familyService.rejectJoinRequest(widget.familyId, uid),
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
      ),
    );
  }
}
