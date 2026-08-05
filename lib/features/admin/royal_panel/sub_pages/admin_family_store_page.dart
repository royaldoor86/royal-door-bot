import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../services/storage_service.dart';
import '../../../../app_theme.dart';

class AdminFamilyStorePage extends StatefulWidget {
  final String? initialType;
  const AdminFamilyStorePage({super.key, this.initialType});

  @override
  State<AdminFamilyStorePage> createState() => _AdminFamilyStorePageState();
}

class _AdminFamilyStorePageState extends State<AdminFamilyStorePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _saleCostController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _durationController = TextEditingController();
  final _effectIdController = TextEditingController();
  final _handNumberController = TextEditingController();
  final _handLettersController = TextEditingController();
  File? _selectedImage;
  late String _selectedType;
  String _selectedCurrency = 'family_gems';
  String _selectedCategory = 'شائع';
  String _selectedMediaType = 'image';
  bool _isLoading = false;

  final List<String> _idCategories = [
    'مقترح',
    'الأفضل',
    'ملحمي',
    'نادر',
    'شائع',
    'ملكي'
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'perk';
    _addDefaultItemsIfEmpty();
  }

  Future<void> _addDefaultItemsIfEmpty() async {
    final snapshot = await _db.collection('family_store_items').limit(1).get();
    if (snapshot.docs.isEmpty) {
      await _addDefaultStoreItems();
    }
  }

  Future<void> _addDefaultStoreItems() async {
    final defaultItems = [
      // شارات
      {
        'name': 'شارة العائلة الذهبية',
        'description': 'شارة مميزة للعائلات المرموقة',
        'imageUrl': '',
        'type': 'badge',
        'cost': 5000,
        'currency': 'family_gems',
        'isActive': true,
        'purchaseCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      // إيديات (أرقام/حروف فقط)
      {
        'name': 'إيد 01',
        'description': 'إيد رقم 01',
        'imageUrl': '',
        'type': 'hand_id',
        'cost': 1000,
        'currency': 'family_gems',
        'handNumber': '01',
        'handLetters': null,
        'category': 'شائع',
        'isActive': true,
        'purchaseCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'إيد ROYAL',
        'description': 'إيد حروف ROYAL',
        'imageUrl': '',
        'type': 'hand_id',
        'cost': 2000,
        'currency': 'family_gems',
        'handNumber': null,
        'handLetters': 'ROYAL',
        'category': 'ملكي',
        'isActive': true,
        'isSold': false,
        'purchaseCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      // تأثيرات الإيديات
      {
        'name': 'تأثير دخول ملكي',
        'description': 'تأثير دخول ملكي فاخر',
        'imageUrl': '',
        'type': 'hand_effect',
        'cost': 5000,
        'currency': 'family_gems',
        'effectId': 'royal_entry',
        'isActive': true,
        'purchaseCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final item in defaultItems) {
      await _db.collection('family_store_items').add(item);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _addStoreItem() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال البيانات المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _imageUrlController.text.trim();
      String? handNumber;
      String? handLetters;

      if (_selectedType == 'hand_id' || _selectedType == 'hand_effect') {
        handNumber = _handNumberController.text.trim().isEmpty
            ? null
            : _handNumberController.text.trim();
        handLetters = _handLettersController.text.trim().isEmpty
            ? null
            : _handLettersController.text.trim();

        if (_selectedType == 'hand_id' &&
            handNumber == null &&
            handLetters == null) {
          throw 'يرجى إدخال رقم أو حروف الإيدي';
        }
      }

      if (_selectedType != 'hand_id') {
        if (_selectedImage != null) {
          imageUrl = await StorageService.uploadRoomImage(_selectedImage!);
        } else if (imageUrl.isEmpty && _selectedType != 'hand_id') {
          // Some types might not strictly need an image if they have an effectId,
          // but usually they do. For hand_id, we explicitly don't need it.
        }
      }

      final cost = int.tryParse(_costController.text) ?? 0;
      final saleCost = int.tryParse(_saleCostController.text);
      final durationDays = int.tryParse(_durationController.text);

      await _db.collection('family_store_items').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'cost': cost,
        'saleCost': (saleCost != null && saleCost > 0) ? saleCost : null,
        'currency': _selectedCurrency,
        'type': _selectedType,
        'category': _selectedType == 'hand_id' ? _selectedCategory : null,
        'effectId': _effectIdController.text.trim().isEmpty
            ? null
            : _effectIdController.text.trim(),
        'durationDays': durationDays,
        'handNumber': handNumber,
        'handLetters': handLetters,
        'mediaType': _selectedType == 'badge' ? _selectedMediaType : null,
        'isActive': true,
        'purchaseCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إضافة العنصر بنجاح ✅'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _costController.clear();
    _saleCostController.clear();
    _imageUrlController.clear();
    _durationController.clear();
    _effectIdController.clear();
    _handNumberController.clear();
    _handLettersController.clear();
    setState(() {
      _selectedImage = null;
      _selectedType = widget.initialType ?? 'perk';
      _selectedCurrency = 'family_gems';
      _selectedCategory = 'شائع';
      _selectedMediaType = 'image';
    });
  }

  Future<void> _deleteItem(String itemId) async {
    await _db.collection('family_store_items').doc(itemId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حذف العنصر'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _toggleItemStatus(String itemId, bool currentStatus) async {
    await _db.collection('family_store_items').doc(itemId).update({
      'isActive': !currentStatus,
    });
  }

  Future<void> _activateAllItems() async {
    try {
      final batch = _db.batch();
      final snapshot = await _db.collection('family_store_items').get();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isActive': true});
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تفعيل جميع عناصر المتجر ✅'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ عند تفعيل العناصر: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('إدارة متجر العائلات',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: Column(
            children: [
              // Form Section
              Flexible(
                child: AppTheme.glassContainer(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إضافة عنصر جديد للمتجر 👑',
                            style: TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 25),

                        // 1. النوع أولاً لتحديد الحقول التالية
                        DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF3D0B16),
                          decoration: InputDecoration(
                            labelText: 'نوع العنصر',
                            labelStyle: const TextStyle(
                                color: Colors.amber, fontSize: 14),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Colors.amber)),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'perk', child: Text('ميزة للعائلة')),
                            DropdownMenuItem(
                                value: 'hand_id',
                                child: Text('إيديات (أرقام/حروف)')),
                            DropdownMenuItem(
                                value: 'hand_effect',
                                child: Text('تأثير الإيديات')),
                            DropdownMenuItem(
                                value: 'entertainment',
                                child: Text('عنصر ترفيهي')),
                            DropdownMenuItem(
                                value: 'badge', child: Text('شارة ملكية')),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedType = value!),
                        ),
                        const SizedBox(height: 20),

                        // 2. الاسم والوصف
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco('اسم العنصر', Icons.title),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: _descriptionController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration:
                              _inputDeco('وصف العنصر', Icons.description),
                        ),
                        const SizedBox(height: 15),

                        // 3. التكلفة والعملة وسعر العرض
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _costController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    _inputDeco('السعر الأساسي', Icons.payments),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _saleCostController,
                                keyboardType: TextInputType.number,
                                style:
                                    const TextStyle(color: Colors.cyanAccent),
                                decoration: _inputDeco(
                                    'سعر العرض (يخصم)', Icons.discount),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedCurrency,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF3D0B16),
                          decoration: _inputDeco(
                              'العملة المستخدمة', Icons.account_balance_wallet),
                          items: const [
                            DropdownMenuItem(
                                value: 'family_gems',
                                child: Text('جواهر العائلة 💎')),
                            DropdownMenuItem(
                                value: 'family_coins',
                                child: Text('كوينز العائلة 🪙')),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedCurrency = value!),
                        ),
                        const SizedBox(height: 20),

                        // 4. الحقول الخاصة بالنوع
                        if (_selectedType == 'hand_id' ||
                            _selectedType == 'hand_effect')
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _handNumberController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration:
                                      _inputDeco('رقم الإيدي', Icons.numbers),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _handLettersController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration:
                                      _inputDeco('حروف الإيدي', Icons.abc),
                                ),
                              ),
                            ],
                          ),

                        if (_selectedType == 'hand_id')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 15),
                              const Text('فئة الإيديات:',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCategory,
                                style: const TextStyle(color: Colors.white),
                                dropdownColor: const Color(0xFF3D0B16),
                                decoration:
                                    _inputDeco('الفئة الملكية', Icons.category),
                                items: _idCategories
                                    .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c,
                                            style: const TextStyle(
                                                color: Colors.white))))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedCategory = value!),
                              ),
                            ],
                          ),

                        if (_selectedType == 'hand_effect')
                          const SizedBox(height: 15),
                        if (_selectedType == 'hand_effect')
                          TextField(
                            controller: _effectIdController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDeco(
                                'معرف التأثير (Effect ID)', Icons.auto_awesome),
                          ),

                        if (_selectedType == 'perk')
                          TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration:
                                _inputDeco('المدة (بالأيام)', Icons.timer),
                          ),

                        // اختيار الصورة (فقط للأنواع التي تحتاج صورة)
                        if (_selectedType != 'hand_id') ...[
                          const SizedBox(height: 20),
                          const Text('تصميم العنصر:',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white.withValues(alpha: 0.05),
                                    border: Border.all(
                                        color: Colors.amber
                                            .withValues(alpha: 0.5)),
                                    image: _selectedImage != null
                                        ? DecorationImage(
                                            image: FileImage(_selectedImage!),
                                            fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: _selectedImage == null
                                      ? const Icon(Icons.add_a_photo,
                                          color: Colors.amber, size: 25)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextField(
                                  controller: _imageUrlController,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                  decoration: const InputDecoration(
                                    hintText: 'أو رابط مباشر (URL)',
                                    hintStyle: TextStyle(color: Colors.white24),
                                    border: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // اختيار نوع الوسائط للشارات
                        if (_selectedType == 'badge') ...[
                          const SizedBox(height: 20),
                          const Text('نوع الوسائط:',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedMediaType,
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: const Color(0xFF3D0B16),
                            decoration:
                                _inputDeco('صيغة العرض', Icons.perm_media),
                            items: const [
                              DropdownMenuItem(
                                  value: 'image', child: Text('صورة (Image)')),
                              DropdownMenuItem(
                                  value: 'png', child: Text('صورة PNG')),
                              DropdownMenuItem(
                                  value: 'video', child: Text('فيديو (Video)')),
                              DropdownMenuItem(
                                  value: 'lottie',
                                  child: Text('Lottie Animation')),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedMediaType = value!),
                          ),
                        ],

                        const SizedBox(height: 30),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _addStoreItem,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.black)
                                    : const Text('نشر العنصر في المتجر ✨',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: _clearForm,
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white54),
                              tooltip: 'مسح الحقول',
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton.icon(
                              onPressed: _activateAllItems,
                              icon: const Icon(Icons.toggle_on,
                                  color: Colors.greenAccent),
                              label: const Text('تفعيل الكل',
                                  style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.green.withValues(alpha: 0.3)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Items List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: widget.initialType != null
                      ? _db
                          .collection('family_store_items')
                          .where('type', isEqualTo: widget.initialType)
                          .orderBy('createdAt', descending: true)
                          .snapshots()
                      : _db
                          .collection('family_store_items')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }

                    final items = snapshot.data!.docs;

                    if (items.isEmpty) {
                      return const Center(
                        child: Text('لا توجد عناصر حالياً',
                            style: TextStyle(color: Colors.white38)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item =
                            items[index].data() as Map<String, dynamic>;
                        final itemId = items[index].id;
                        final isActive = item['isActive'] ?? true;
                        final int? salePrice = item['saleCost'];

                        return AppTheme.glassContainer(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white10,
                                backgroundImage: item['imageUrl'] != null &&
                                        item['imageUrl'].isNotEmpty
                                    ? NetworkImage(item['imageUrl'])
                                    : null,
                                child: (item['imageUrl'] == null ||
                                        item['imageUrl'].isEmpty)
                                    ? const Icon(Icons.stars,
                                        color: Colors.amber, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(item['name'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (salePrice != null) ...[
                                          Text('${item['cost']}',
                                              style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 10,
                                                  decoration: TextDecoration
                                                      .lineThrough)),
                                          const SizedBox(width: 5),
                                          Text('$salePrice',
                                              style: const TextStyle(
                                                  color: Colors.cyanAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11)),
                                        ] else
                                          Text('${item['cost']}',
                                              style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11)),
                                        const SizedBox(width: 4),
                                        Icon(
                                            item['currency'] == 'family_gems'
                                                ? Icons.diamond
                                                : Icons.stars,
                                            size: 10,
                                            color: item['currency'] ==
                                                    'family_gems'
                                                ? Colors.cyan
                                                : Colors.amber),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    _getTypeBadge(item['type']),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isActive,
                                onChanged: (value) =>
                                    _toggleItemStatus(itemId, isActive),
                                activeTrackColor:
                                    Colors.green.withValues(alpha: 0.4),
                                activeThumbColor: Colors.green,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteItem(itemId),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.amber, size: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amber)),
    );
  }

  Widget _getTypeBadge(String? type) {
    String text = 'غير معروف';
    Color color = Colors.grey;

    switch (type) {
      case 'perk':
        text = 'ميزة';
        color = Colors.blue;
        break;
      case 'hand_id':
        text = 'إيديات';
        color = Colors.purple;
        break;
      case 'hand_effect':
        text = 'تأثير';
        color = Colors.pink;
        break;
      case 'entertainment':
        text = 'ترفيه';
        color = Colors.orange;
        break;
      case 'badge':
        text = 'شارة';
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
