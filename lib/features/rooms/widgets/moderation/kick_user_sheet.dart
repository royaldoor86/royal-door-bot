import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/anti_kick_service.dart';

class KickUserSheet extends StatefulWidget {
  final String roomId;
  final String userId;
  final String userName;

  const KickUserSheet(
      {super.key,
      required this.roomId,
      required this.userId,
      required this.userName});

  @override
  State<KickUserSheet> createState() => _KickUserSheetState();
}

class _KickUserSheetState extends State<KickUserSheet> {
  bool _isChecking = false;
  bool _canKick = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCanKick();
  }

  Future<void> _checkCanKick() async {
    setState(() => _isChecking = true);

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canKick =
        await AntiKickService.canKickUser(widget.userId, currentUserId);

    setState(() {
      _canKick = canKick;
      _isChecking = false;
      if (!canKick) {
        _errorMessage = 'لا يمكن طرد هذا المستخدم بسبب مضاد الطرد 🛡️';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
        decoration: const BoxDecoration(
            color: Color(0xFF1A242F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text("طرد ${widget.userName} من الغرفة",
              style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorMessage,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
          if (_isChecking)
            const CircularProgressIndicator(color: Colors.orangeAccent)
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _canKick ? Colors.orangeAccent : Colors.grey,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _canKick
                  ? () async {
                      // تسجيل محاولة الطرد
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid ?? '';
                      await AntiKickService.logKickAttempt(
                          widget.userId, currentUserId, true);

                      await FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(widget.roomId)
                          .collection('online_users')
                          .doc(widget.userId)
                          .delete();
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text("تأكيد الطرد",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 10),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("إلغاء", style: TextStyle(color: Colors.white54))),
        ],
      ),
      ),
    );
  }
}
