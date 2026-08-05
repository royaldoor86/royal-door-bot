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
  int _calculatedResult = 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateResult);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateResult() {
    final int amount = int.tryParse(_amountController.text) ?? 0;
    setState(() {
      if (_selectedCurrency == 'gems') {
        _calculatedResult = amount * 2;
      } else {
        _calculatedResult = amount ~/ 2;
      }
    });
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
                'حول رصيدك بسهولة بين الجواهر والكوينز. الحد الأدنى للتحويل هو 100 وحدة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          if (user != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final gems = (data?['gems'] ?? 0).toInt();
                final coins = (data?['coins'] ?? 0).toInt();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _balanceBox('جواهر 💎', gems.toString(), Colors.cyan),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.white10,
                            ),
                            _balanceBox('كوينز 🪙', coins.toString(), AppTheme.royalGold),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildTransferForm(gems, coins),
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

  Widget _buildTransferForm(int gems, int coins) {
    bool isGems = _selectedCurrency == 'gems';
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _currencyChoice('gems', 'من جواهر', Icons.diamond, Colors.cyan)),
            const SizedBox(width: 10),
            Expanded(child: _currencyChoice('coins', 'من كوينز', Icons.monetization_on, AppTheme.royalGold)),
          ],
        ),
        const SizedBox(height: 25),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'المبلغ المراد تحويله',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 16),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Icon(isGems ? Icons.diamond : Icons.monetization_on, 
                color: (isGems ? Colors.cyan : AppTheme.royalGold).withValues(alpha: 0.5)),
            ),
          ],
        ),
        if (_calculatedResult > 0)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ستحصل على: ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    '$_calculatedResult ${isGems ? 'كوينز 🪙' : 'جواهر 💎'}',
                    style: TextStyle(
                      color: isGems ? AppTheme.royalGold : Colors.cyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: isGems 
                  ? [Colors.cyan, Colors.blue.shade900]
                  : [AppTheme.royalGold, Colors.orange.shade900],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isGems ? Colors.cyan : AppTheme.royalGold).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _isProcessing ? null : () => _processTransfer(gems, coins),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('تأكيد عملية التحويل',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text('سعر الصرف: 1 جوهرة = 2 كوينز | 2 كوينز = 1 جوهرة',
          style: TextStyle(color: Colors.white24, fontSize: 10)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _currencyChoice(String type, String label, IconData icon, Color color) {
    bool selected = _selectedCurrency == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCurrency = type);
        _calculateResult();
      },
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

  void _processTransfer(int gems, int coins) async {
    final int amount = int.tryParse(_amountController.text) ?? 0;
    
    if (amount < 100) {
      _showMsg('الحد الأدنى للتحويل هو 100');
      return;
    }

    if (_selectedCurrency == 'gems') {
      if (gems < amount) {
        _showMsg('رصيد الجواهر غير كافٍ');
        return;
      }
    } else {
      if (coins < amount) {
        _showMsg('رصيد الكوينز غير كافٍ');
        return;
      }
    }

    setState(() => _isProcessing = true);
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        if (_selectedCurrency == 'gems') {
          int coinsToAdd = amount * 2;
          tx.update(userRef, {
            'gems': FieldValue.increment(-amount),
            'coins': FieldValue.increment(coinsToAdd),
            'stars': FieldValue.increment(coinsToAdd),
          });
        } else {
          int gemsToAdd = amount ~/ 2;
          tx.update(userRef, {
            'coins': FieldValue.increment(-amount),
            'stars': FieldValue.increment(-amount),
            'gems': FieldValue.increment(gemsToAdd),
          });
        }
      });

      _showMsg('تم التحويل بنجاح ✅', isError: false);
      if (mounted) {
        _amountController.clear();
        Navigator.pop(context);
      }
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
