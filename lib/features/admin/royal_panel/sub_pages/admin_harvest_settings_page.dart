import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/harvest_service.dart';

class AdminHarvestSettingsPage extends StatefulWidget {
  const AdminHarvestSettingsPage({super.key});

  @override
  State<AdminHarvestSettingsPage> createState() => _AdminHarvestSettingsPageState();
}

class _AdminHarvestSettingsPageState extends State<AdminHarvestSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  final _exchangeRateController = TextEditingController();
  final _minWithdrawalController = TextEditingController();
  final _feeController = TextEditingController();
  bool _isMaintenance = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _db.collection('settings').doc('harvest_config').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _exchangeRateController.text = (data['exchangeRate'] ?? 2.6).toString();
          _minWithdrawalController.text = (data['minWithdrawalAmount'] ?? 150000.0).toString();
          _feeController.text = ((data['transferFee'] ?? 0.05) * 100).toString();
          _isMaintenance = data['isMaintenance'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _exchangeRateController.text = "2.6";
          _minWithdrawalController.text = "150000";
          _feeController.text = "5";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _db.collection('settings').doc('harvest_config').set({
        'exchangeRate': double.parse(_exchangeRateController.text),
        'minWithdrawalAmount': double.parse(_minWithdrawalController.text),
        'transferFee': double.parse(_feeController.text) / 100,
        'isMaintenance': _isMaintenance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الإعدادات بنجاح ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFFFD700);
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF021B2B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF021B2B),
          title: const Text('إعدادات الحصاد الملكي', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: goldColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('الإعدادات المالية'),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _exchangeRateController,
                      label: 'سعر الصرف (لكل 1000 جوهرة)',
                      hint: 'مثال: 2.6 يعني 2600 دينار',
                      icon: Icons.currency_exchange,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _minWithdrawalController,
                      label: 'الحد الأدنى للسحب (دينار)',
                      hint: 'مثال: 150000',
                      icon: Icons.payments_outlined,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _feeController,
                      label: 'رسوم التحويل (%)',
                      hint: 'مثال: 5 تعني 5%',
                      icon: Icons.percent,
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle('حالة النظام'),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('وضع الصيانة', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('تعطيل عمليات الشراء والسحب مؤقتاً', style: TextStyle(color: Colors.white54)),
                      value: _isMaintenance,
                      activeColor: goldColor,
                      onChanged: (val) => setState(() => _isMaintenance = val),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD700)),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'هذا الحقل مطلوب';
        if (double.tryParse(val) == null) return 'يرجى إدخال رقم صحيح';
        return null;
      },
    );
  }
}
