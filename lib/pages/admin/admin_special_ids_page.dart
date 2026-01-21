// lib/pages/admin/admin_special_ids_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AdminSpecialIdsPage extends StatefulWidget {
  const AdminSpecialIdsPage({super.key});

  @override
  State<AdminSpecialIdsPage> createState() => _AdminSpecialIdsPageState();
}

class _AdminSpecialIdsPageState extends State<AdminSpecialIdsPage> {
  final _valueCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _batchValuesCtrl = TextEditingController();
  final _grantCtrl = TextEditingController();

  String _selectedCategory = 'شائع';
  bool _showInStore = true;
  bool _onSale = false;
  bool _isBatchMode = false;
  bool _isLoading = false;

  final List<String> _categories = ['مقترح', 'الأفضل', 'ملحمي', 'نادر', 'شائع'];
  final _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    _batchValuesCtrl.dispose();
    _grantCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSpecialId({String? docId}) async {
    if (_isBatchMode && docId == null) {
      await _processBatchAdd();
      return;
    }

    final value = _valueCtrl.text.trim().toUpperCase();
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (value.isEmpty || price <= 0) {
      _snack('يرجى ملء الحقول المطلوبة');
      return;
    }

    setState(() => _isLoading = true);
    final data = {
      'value': value,
      'price': price,
      'salePrice':
          _onSale ? (int.tryParse(_salePriceCtrl.text.trim()) ?? 0) : 0,
      'category': _selectedCategory,
      'onSale': _onSale,
      'showInStore': _showInStore,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (docId == null) {
        await _db.collection('special_ids').add({
          ...data,
          'isSold': false,
          'createdAt': FieldValue.serverTimestamp()
        });
        _snack('تمت الإضافة بنجاح 👑');
      } else {
        await _db.collection('special_ids').doc(docId).update(data);
        _snack('تم التحديث بنجاح ✅');
      }
      _clearForm();
    } catch (e) {
      _snack('خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processBatchAdd() async {
    final valuesStr = _batchValuesCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (valuesStr.isEmpty || price <= 0) {
      _snack('أدخل المعرفات والسعر');
      return;
    }

    setState(() => _isLoading = true);
    final List<String> idList = valuesStr
        .split(',')
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      final batch = _db.batch();
      for (var id in idList) {
        final docRef = _db.collection('special_ids').doc();
        batch.set(docRef, {
          'value': id,
          'price': price,
          'category': _selectedCategory,
          'onSale': false,
          'isSold': false,
          'showInStore': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      _snack('تمت إضافة ${idList.length} معرف بنجاح 🎉');
      _clearForm();
    } catch (e) {
      _snack('خطأ في الإضافة الجماعية: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _valueCtrl.clear();
    _priceCtrl.clear();
    _salePriceCtrl.clear();
    _batchValuesCtrl.clear();
    setState(() {
      _onSale = false;
      _isBatchMode = false;
    });
  }

  void _editId(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    _valueCtrl.text = d['value'];
    _priceCtrl.text = d['price'].toString();
    _salePriceCtrl.text = (d['salePrice'] ?? 0).toString();
    setState(() {
      _selectedCategory = d['category'] ?? 'شائع';
      _onSale = d['onSale'] ?? false;
      _showInStore = d['showInStore'] ?? true;
      _isBatchMode = false;
    });
    _showFormSheet(docId: doc.id);
  }

  void _showFormSheet({String? docId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setST) => Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      left: 20,
                      right: 20,
                      top: 20),
                  decoration: const BoxDecoration(
                      color: Color(0xFF1A0A10),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30))),
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(docId == null ? "إضافة معرفات جديدة" : "تعديل معرف",
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      if (docId == null)
                        SwitchListTile(
                          title: const Text("إضافة جماعية (Batch Add)",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14)),
                          value: _isBatchMode,
                          onChanged: (v) => setST(() {
                            _isBatchMode = v;
                            setState(() {});
                          }),
                        ),
                      const SizedBox(height: 15),
                      _isBatchMode
                          ? _adminField(
                              _batchValuesCtrl,
                              "اكتب المعرفات مفصولة بفاصلة (مثال: 111, 222, 333)",
                              Icons.list,
                              maxLines: 3)
                          : _adminField(_valueCtrl, "قيمة المعرف", Icons.tag),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _adminField(
                                _priceCtrl, "السعر", Icons.diamond,
                                isNum: true)),
                        if (!_isBatchMode) const SizedBox(width: 10),
                        if (!_isBatchMode)
                          Expanded(
                              child: _adminField(
                                  _salePriceCtrl, "سعر الخصم", Icons.discount,
                                  isNum: true, enabled: _onSale)),
                      ]),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: const Color(0xFF1A0A10),
                        decoration:
                            _fieldDecoration("الفئة الملكية", Icons.category),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style:
                                        const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (v) => setST(() {
                          _selectedCategory = v!;
                          setState(() {});
                        }),
                      ),
                      if (!_isBatchMode)
                        SwitchListTile(
                            title: const Text("تفعيل الخصم",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            value: _onSale,
                            onChanged: (v) => setST(() {
                                  _onSale = v;
                                  setState(() {});
                                })),
                      SwitchListTile(
                          title: const Text("عرض في المتجر",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          value: _showInStore,
                          onChanged: (v) => setST(() {
                                _showInStore = v;
                                setState(() {});
                              })),
                      const SizedBox(height: 20),
                      AppTheme.gradientButton(
                          text:
                              _isLoading ? "جاري الحفظ..." : "حفظ المعلومات 👑",
                          onPressed: _isLoading
                              ? null
                              : () => _saveSpecialId(docId: docId)),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              )),
    );
  }

  void _snack(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
              title: const Text('إدارة الـ ID المميز 👑')),
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                _clearForm();
                _showFormSheet();
              },
              icon: const Icon(Icons.add),
              label: const Text("إضافة")),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('special_ids')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (c, i) => _buildIdAdminTile(docs[i]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIdAdminTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isSold = data['isSold'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['value'],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(data['category'],
                style: const TextStyle(color: Colors.amber, fontSize: 11)),
          ]),
          Row(children: [
            IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: () => _editId(doc)),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
                onPressed: () => _confirmDelete(doc.id, data['value'])),
          ]),
        ]),
        const Divider(color: Colors.white10),
        if (!isSold)
          Row(children: [
            Expanded(
                child: _adminField(
                    _grantCtrl, "منح لمستخدم (ID أو UID)", Icons.person_add)),
            IconButton(
                icon: const Icon(Icons.send, color: Colors.amber),
                onPressed: () =>
                    _grantIdToUser(specialDocId: doc.id, newId: data['value'])),
          ])
        else
          const Text("الحالة: مباع / ممنوح ✅",
              style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
      ]),
    );
  }

  void _confirmDelete(String id, String val) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1A0A10),
                title: const Text("حذف المعرف"),
                content: Text("هل أنت متأكد من حذف $val نهائياً؟"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("إلغاء")),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _db.collection('special_ids').doc(id).delete();
                      },
                      child: const Text("حذف",
                          style: TextStyle(color: Colors.redAccent)))
                ]));
  }

  Future<void> _grantIdToUser(
      {required String specialDocId, required String newId}) async {
    final input = _grantCtrl.text.trim();
    if (input.isEmpty) {
      _snack('أدخل UID أو shortId للمستخدم');
      return;
    }
    setState(() => _isLoading = true);
    try {
      QuerySnapshot q = await _db
          .collection('users')
          .where('shortId', isEqualTo: input.toUpperCase())
          .limit(1)
          .get();

      // تم الإصلاح هنا بتعريف النوع الصريح لتجنب Object Error
      DocumentSnapshot userDoc;
      if (q.docs.isNotEmpty) {
        userDoc = q.docs.first;
      } else {
        userDoc = await _db.collection('users').doc(input).get();
      }

      if (!userDoc.exists) throw 'لم يتم العثور على المستخدم';

      await _db.runTransaction((tx) async {
        tx.update(_db.collection('users').doc(userDoc.id), {
          'shortId': newId,
          'shortIdChangedAt': FieldValue.serverTimestamp()
        });
        tx.update(_db.collection('special_ids').doc(specialDocId), {
          'isSold': true,
          'ownerUid': userDoc.id,
          'grantedAt': FieldValue.serverTimestamp()
        });
      });
      _snack('تم منح المعرف بنجاح 👑');
    } catch (e) {
      _snack('فشل: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _adminField(TextEditingController ctrl, String label, IconData icon,
      {bool isNum = false, bool enabled = true, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: _fieldDecoration(label, icon),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.amber, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none));
  }
}
