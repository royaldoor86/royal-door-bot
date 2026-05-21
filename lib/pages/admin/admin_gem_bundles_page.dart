// lib/pages/admin/admin_gem_bundles_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';

/// صفحة إدارة باقات الجواهر 👑
class AdminGemBundlesPage extends StatefulWidget {
  const AdminGemBundlesPage({super.key});

  @override
  State<AdminGemBundlesPage> createState() => _AdminGemBundlesPageState();
}

class _AdminGemBundlesPageState extends State<AdminGemBundlesPage> {
  bool _loading = false;

  CollectionReference<Map<String, dynamic>> get _bundlesRef =>
      FirebaseFirestore.instance.collection('gem_bundles');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppTheme.background(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'باقات الجواهر',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _loading ? null : () => _openBundleEditor(),
            backgroundColor: const Color(0xFFFFB300),
            child: const Icon(Icons.add, color: Colors.black),
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _bundlesRef.orderBy('gems', descending: false).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'حدث خطأ في تحميل الباقات',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد باقات جواهر حالياً، قم بإضافة باقة جديدة 👑',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index];
                  final data = d.data();
                  final name = (data['name'] ?? '').toString();
                  final gems = _parseDouble(data['gems'] ?? 0);
                  final price = _parseDouble(data['price'] ?? 0);
                  final priceText = (data['priceText'] ?? '').toString();
                  final onSale = (data['onSale'] ?? false) == true;
                  final salePrice = data['salePrice'] != null
                      ? _parseDouble(data['salePrice'])
                      : null;
                  final salePriceText =
                      (data['salePriceText'] ?? '').toString();
                  final active = (data['active'] ?? true) == true;

                  return _GemBundleCard(
                    name: name,
                    gems: gems.toInt(),
                    price: price,
                    priceText: priceText,
                    onSale: onSale,
                    salePrice: salePrice,
                    salePriceText: salePriceText,
                    active: active,
                    onEdit: () => _openBundleEditor(
                      docId: d.id,
                      initialData: data,
                    ),
                    onDelete: () => _deleteBundle(d.id, name),
                    onToggleActive: () => _toggleActive(d.id, current: active),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    }
    return 0.0;
  }

  /// فتح نافذة إضافة / تعديل باقة
  Future<void> _openBundleEditor({
    String? docId,
    Map<String, dynamic>? initialData,
  }) async {
    final bool isEdit = docId != null;
    final nameController =
        TextEditingController(text: (initialData?['name'] ?? '').toString());
    final gemsController =
        TextEditingController(text: (initialData?['gems'] ?? '').toString());
    final priceController =
        TextEditingController(text: (initialData?['price'] ?? '').toString());
    final priceTextController = TextEditingController(
        text: (initialData?['priceText'] ?? '').toString());

    final salePriceController = TextEditingController(
        text: (initialData?['salePrice'] ?? '').toString());
    final salePriceTextController = TextEditingController(
        text: (initialData?['salePriceText'] ?? '').toString());

    bool onSale = (initialData?['onSale'] ?? false) == true;
    bool active = (initialData?['active'] ?? true) == true;

    await showDialog(
      context: context,
      barrierDismissible: !_loading,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A0B4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEdit ? 'تعديل باقة جواهر' : 'إضافة باقة جواهر',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: nameController,
                      label: 'اسم الباقة',
                      hint: 'مثال: باقة ملكية',
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: gemsController,
                      label: 'عدد الجواهر',
                      hint: 'مثال: 5000',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: priceController,
                      label: 'السعر الأساسي',
                      hint: 'مثال: 5.99',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: priceTextController,
                      label: 'وصف السعر (اختياري)',
                      hint: 'مثال: 5.99 دينار',
                    ),
                    const Divider(height: 20, color: Colors.white24),
                    SwitchListTile(
                      value: onSale,
                      onChanged: (v) => setLocal(() => onSale = v),
                      title: const Text(
                        'تفعيل عرض/خصم على هذه الباقة',
                        style: TextStyle(color: Colors.white),
                      ),
                      activeThumbColor: const Color(0xFFFFB300),
                    ),
                    if (onSale) ...[
                      _buildTextField(
                        controller: salePriceController,
                        label: 'سعر العرض',
                        hint: 'مثال: 3.99',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: salePriceTextController,
                        label: 'وصف سعر العرض (اختياري)',
                        hint: 'مثال: 3.99 دينار لفترة محدودة',
                      ),
                    ],
                    const Divider(height: 20, color: Colors.white24),
                    SwitchListTile(
                      value: active,
                      onChanged: (v) => setLocal(() => active = v),
                      title: const Text(
                        'تفعيل الباقة (ظهور في المتجر)',
                        style: TextStyle(color: Colors.white),
                      ),
                      activeThumbColor: const Color(0xFFFFB300),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          await _saveBundle(
                            isEdit: isEdit,
                            docId: docId,
                            name: nameController.text.trim(),
                            gems: gemsController.text.trim(),
                            price: priceController.text.trim(),
                            priceText: priceTextController.text.trim(),
                            onSale: onSale,
                            salePrice: salePriceController.text.trim(),
                            salePriceText: salePriceTextController.text.trim(),
                            active: active,
                            dialogContext: ctx,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'حفظ التعديلات' : 'إضافة الباقة',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveBundle({
    required bool isEdit,
    required String? docId,
    required String name,
    required String gems,
    required String price,
    required String priceText,
    required bool onSale,
    required String salePrice,
    required String salePriceText,
    required bool active,
    required BuildContext dialogContext,
  }) async {
    if (name.isEmpty || gems.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال الاسم، عدد الجواهر، والسعر الأساسي'),
        ),
      );
      return;
    }

    final int? gemsInt = int.tryParse(gems);
    final double? priceDouble = double.tryParse(price);
    final double? salePriceDouble =
        salePrice.isEmpty ? null : double.tryParse(salePrice);

    if (gemsInt == null || priceDouble == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تأكد من أن عدد الجواهر والسعر أرقام صحيحة'),
        ),
      );
      return;
    }

    if (onSale && (salePriceDouble == null || salePriceDouble <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل سعر عرض صالح أو أوقف خيار الخصم'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final now = FieldValue.serverTimestamp();

      final data = <String, dynamic>{
        'name': name,
        'gems': gemsInt,
        'price': priceDouble,
        'priceText': priceText,
        'onSale': onSale,
        'salePrice': onSale ? salePriceDouble : null,
        'salePriceText': onSale ? salePriceText : null,
        'active': active,
        'updatedAt': now,
      };

      // Close the dialog before performing the async write to avoid using
      // the dialog BuildContext across an async gap.
      try {
        Navigator.pop(dialogContext);
      } catch (_) {}

      if (isEdit && docId != null) {
        await _bundlesRef.doc(docId).update(data);
      } else {
        await _bundlesRef.add({
          ...data,
          'createdAt': now,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'تم حفظ التعديلات ✅' : 'تم إضافة الباقة ✅'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حفظ الباقة: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteBundle(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0B4A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'حذف الباقة',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'هل أنت متأكد من حذف الباقة "$name"؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _bundlesRef.doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الباقة بنجاح ✅'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف الباقة: $e'),
        ),
      );
    }
  }

  Future<void> _toggleActive(String docId, {required bool current}) async {
    try {
      await _bundlesRef.doc(docId).update({'active': !current});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تغيير حالة الباقة: $e'),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

/// كرت الباقة في القائمة
class _GemBundleCard extends StatelessWidget {
  final String name;
  final int gems;
  final double price;
  final String priceText;
  final bool onSale;
  final double? salePrice;
  final String salePriceText;
  final bool active;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _GemBundleCard({
    required this.name,
    required this.gems,
    required this.price,
    required this.priceText,
    required this.onSale,
    required this.salePrice,
    required this.salePriceText,
    required this.active,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // السطر الأول: الاسم + الحالة
          Row(
            children: [
              Text(
                name.isEmpty ? 'باقة بدون اسم' : name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(Icons.diamond, size: 16, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    gems.toString(),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: onToggleActive,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (active ? Colors.green : Colors.grey)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        active ? 'مفعّل' : 'مخفي',
                        style: TextStyle(
                          color: active ? Colors.green : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // السعر
          Row(
            children: [
              const Text(
                'السعر: ',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (onSale && salePrice != null) ...[
                Text(
                  price.toString(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  salePrice.toString(),
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Text(
                  price.toString(),
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),

          if (priceText.isNotEmpty)
            Text(
              priceText,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),

          if (onSale && salePriceText.isNotEmpty)
            Text(
              salePriceText,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text(
                    'تعديل',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text(
                    'حذف',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
