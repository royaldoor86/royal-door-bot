import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/rewards_service.dart';

class RoomEarningsSheet extends StatefulWidget {
  final String roomId;
  const RoomEarningsSheet({super.key, required this.roomId});

  @override
  State<RoomEarningsSheet> createState() => _RoomEarningsSheetState();
}

class _RoomEarningsSheetState extends State<RoomEarningsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1A24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.amberAccent, width: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('مكافآت الغرفة الملكية',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const Text('تحصل على 1% من قيمة كل هدية في غرفتك',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final double pendingEarnings =
                    _parseDouble(data['pendingEarnings'] ?? 0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        RotationTransition(
                          turns: _rotationController,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(colors: [
                                Colors.amber.withValues(alpha: 0),
                                Colors.amber.withValues(alpha: 0.5),
                                Colors.amber.withValues(alpha: 0)
                              ]),
                            ),
                          ),
                        ),
                        Container(
                          width: 150,
                          height: 150,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1B2B38),
                              boxShadow: [
                                BoxShadow(color: Colors.black45, blurRadius: 15)
                              ]),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stars_rounded,
                                  color: Colors.amber, size: 40),
                              const SizedBox(height: 8),
                              Text(pendingEarnings.toStringAsFixed(2),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const Text('نجوم ⭐',
                                  style: TextStyle(
                                      color: Colors.amber, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pendingEarnings > 0
                                ? Colors.amber
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 10,
                            shadowColor: Colors.amber.withValues(alpha: 0.3),
                          ),
                          onPressed: pendingEarnings > 0
                              ? () => _collectEarnings(pendingEarnings)
                              : null,
                          child: const Text('جمع المكافآت الآن',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
                'ملاحظة: سيتم تحويل المكافآت مباشرة إلى محفظتك الشخصية 💰',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _collectEarnings(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final rewardsService = RewardsService();

    try {
      // استخدام الخدمة المركزية بدلاً من التحديث المباشر
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
        'pendingEarnings': 0,
      });

      await rewardsService.addRewardToWallet(user.uid, amount, 'stars');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('مبروك! تم جمع ${amount.toInt()} نجوم ⭐ بنجاح 🏆'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('فشل في جمع المكافآت ❌'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    }
    return 0.0;
  }
}
