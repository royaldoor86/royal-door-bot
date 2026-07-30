import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app_theme.dart';

class TransferCurrencySheet extends StatefulWidget {
  final String roomId;
  const TransferCurrencySheet({super.key, required this.roomId});

  @override
  State<TransferCurrencySheet> createState() => _TransferCurrencySheetState();
}

class _TransferCurrencySheetState extends State<TransferCurrencySheet> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'gems';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 45,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          const Text('تحويل العملات الملكي 🔄',
              style: TextStyle(
                  color: AppTheme.royalGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
                'يمكنك تحويل الجواهر إلى نجوم أو العكس لدعم الغرفة أو شراء الهدايا.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          if (user != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final gems = (data?['gems'] ?? 0).toInt();
                final stars = (data?['stars'] ?? data?['coins'] ?? 0).toInt();

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _balanceBox('جواهر 💎', gems.toString(), Colors.cyan),
                          const Icon(Icons.compare_arrows, color: Colors.white24),
                          _balanceBox('نجوم ⭐', stars.toString(), Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildTransferForm(gems, stars),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _balanceBox(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(children: [
        Text(val,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }

  Widget _buildTransferForm(int gems, int stars) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _currencyChoice('gems', 'تحويل من جواهر', Icons.diamond, Colors.cyan),
            const SizedBox(width: 15),
            _currencyChoice('stars', 'تحويل من نجوم', Icons.stars, Colors.amber),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 20),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'أدخل المبلغ',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _isProcessing ? null : () => _processTransfer(gems, stars),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text('تأكيد التحويل الآن',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _currencyChoice(String type, String label, IconData icon, Color color) {
    bool selected = _selectedCurrency == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedCurrency = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? color : Colors.white10, width: 1)),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: selected ? color : Colors.white38, fontSize: 12)),
        ]),
      ),
    );
  }

  void _processTransfer(int gems, int stars) async {
    final int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    if (_selectedCurrency == 'gems' && gems < amount) {
      _showMsg('رصيد الجواهر غير كافٍ');
      return;
    }
    if (_selectedCurrency == 'stars' && stars < amount) {
      _showMsg('رصيد النجوم غير كافٍ');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        if (_selectedCurrency == 'gems') {
          tx.update(userRef, {
            'gems': FieldValue.increment(-amount),
            'stars': FieldValue.increment(amount),
            'coins': FieldValue.increment(amount),
          });
        } else {
          tx.update(userRef, {
            'stars': FieldValue.increment(-amount),
            'coins': FieldValue.increment(-amount),
            'gems': FieldValue.increment(amount),
          });
        }
      });

      _showMsg('تم التحويل بنجاح ✅', isError: false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMsg('فشل التحويل: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showMsg(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green));
  }
}
