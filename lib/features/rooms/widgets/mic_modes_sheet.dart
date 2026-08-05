import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MicModesSheet extends StatefulWidget {
  final String roomId;
  final String currentMode;

  const MicModesSheet(
      {super.key, required this.roomId, required this.currentMode});

  @override
  State<MicModesSheet> createState() => _MicModesSheetState();
}

class _MicModesSheetState extends State<MicModesSheet> {
  late String _selectedMode;
  int _roomLevel = 1;
  int _userGems = 0;
  List<String> _purchasedModes = [];

  final Map<String, int> _modeCosts = {
    'chat-5': 0,
    'broadcast-5': 0,
    'normal': 15000,
    '2-4-4': 15000,
    'broadcast-11': 20000,
    'chat-15': 25000,
  };

  final Map<String, int> _modeSeats = {
    'chat-5': 5,
    'broadcast-5': 5,
    'normal': 10,
    '2-4-4': 10,
    'broadcast-11': 11,
    'chat-15': 15,
  };

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
    _loadData();
  }

  Future<void> _loadData() async {
    final roomDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (mounted) {
      setState(() {
        _roomLevel = roomDoc.data()?['level'] ?? 1;
        _purchasedModes = List<String>.from(roomDoc.data()?['purchasedMicModes'] ?? []);
        _userGems = (userDoc.data()?['gems'] ?? 0).toInt();
      });
    }
  }

  bool _isModePurchased(String mode) {
    if (_modeCosts[mode] == 0) return true;
    return _purchasedModes.contains(mode);
  }

  Future<void> _saveMode() async {
    if (_selectedMode == widget.currentMode) {
      Navigator.pop(context);
      return;
    }

    final cost = _modeCosts[_selectedMode] ?? 0;
    final isPurchased = _isModePurchased(_selectedMode);

    try {
      if (!isPurchased && cost > 0) {
        // عملية الشراء والتحويل
        await _handlePurchase(cost);
      } else {
        // تغيير النمط فقط إذا كان مشترياً بالفعل أو مجانياً
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .update({
          'micMode': _selectedMode,
          'maxSeats': _modeSeats[_selectedMode] ?? 8,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تفعيل نمط المايكات الجديد بنجاح ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل الإجراء: ${e.toString()}')));
      }
    }
  }

  Future<void> _handlePurchase(int cost) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_userGems < cost) {
      throw Exception('رصيد الجواهر غير كافٍ! تحتاج إلى $cost جوهرة 💎');
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

      final userSnapshot = await transaction.get(userRef);
      final currentGems = (userSnapshot.data()?['gems'] ?? 0).toInt();

      if (currentGems < cost) {
        throw Exception('رصيد الجواهر غير كافٍ!');
      }

      // خصم الجواهر
      transaction.update(userRef, {'gems': currentGems - cost});

      // إضافة النمط للمشتريات وتحديث النمط الحالي
      transaction.update(roomRef, {
        'micMode': _selectedMode,
        'maxSeats': _modeSeats[_selectedMode] ?? 8,
        'purchasedMicModes': FieldValue.arrayUnion([_selectedMode])
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(top: BorderSide(color: Colors.amberAccent, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("نمط المايكات",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.diamond, color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 5),
                    Text('$_userGems', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildModeCard("دردشة - 5 مايكات", "chat-5", [5]),
                _buildModeCard("بث - 5 مايكات", "broadcast-5", [1, 4]),
                _buildModeCard("فريق - 10 مايكات", "2-4-4", [2, 4, 4], cost: 15000),
                _buildModeCard("دردشة - 10 مايكات", "normal", [5, 5], cost: 15000),
                _buildModeCard("بث - 11 مايك", "broadcast-11", [1, 4, 6], cost: 20000),
                _buildModeCard("دردشة - 15 مايك", "chat-15", [5, 5, 5], cost: 25000),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saveMode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
            ),
            child: Text(
              _isModePurchased(_selectedMode) ? "تأكيد التفعيل" : "شراء وتفعيل (${_modeCosts[_selectedMode]} 💎)",
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(String title, String mode, List<int> rows, {int cost = 0}) {
    bool isSelected = _selectedMode == mode;
    bool isPurchased = _isModePurchased(mode);

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black26,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: isSelected ? Colors.greenAccent : Colors.white10,
              width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: Colors.greenAccent, size: 16),
                if (!isPurchased && cost > 0)
                  const Icon(Icons.lock, color: Colors.amber, size: 14),
                Expanded(
                  child: Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70)),
                ),
              ],
            ),
            if (!isPurchased && cost > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('$cost 💎', style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 10),
            Column(
              children: rows
                  .map((count) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            count,
                            (index) => Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                            ? Colors.greenAccent
                                            : Colors.white38,
                                    shape: BoxShape.circle,
                                  ),
                                )),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
