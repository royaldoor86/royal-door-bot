import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'voice_room_page.dart';
import '../services/ad_manager.dart';

class CreateVipRoomPage extends StatefulWidget {
  final int maxMics;
  final String vipName;
  const CreateVipRoomPage(
      {super.key, required this.maxMics, required this.vipName});

  @override
  State<CreateVipRoomPage> createState() => _CreateVipRoomPageState();
}

class _CreateVipRoomPageState extends State<CreateVipRoomPage> {
  final TextEditingController _nameController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _loading = false;

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('إنشاء غرفة ${widget.vipName}', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('عدد المايكات: ${widget.maxMics}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'اسم الغرفة',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
              ),
            ),
            const SizedBox(height: 30),
            _loading
                ? const CircularProgressIndicator(color: Colors.amber)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى إدخال اسم الغرفة'))
                        );
                        return;
                      }
                      setState(() => _loading = true);
                      try {
                        final roomId = await _firestoreService.createRoom(
                          ownerId: _currentUserId,
                          roomName: _nameController.text.trim(),
                          maxSeats: widget.maxMics,
                        );
                        if (!mounted) return;
                        setState(() => _loading = false);

                        // إظهار إعلان ملء الشاشة بعد إنشاء الغرفة
                        AdManager().showInterstitialAd();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VoiceRoomPage(
                              roomId: roomId,
                              roomName: _nameController.text.trim(),
                              ownerId: _currentUserId,
                            ),
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          setState(() => _loading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ: $e'))
                          );
                        }
                      }
                    },
                    child: const Text('إنشاء الغرفة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}
