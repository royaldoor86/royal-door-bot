import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FamilyFullPage extends StatefulWidget {
  const FamilyFullPage({super.key});

  @override
  State<FamilyFullPage> createState() => _FamilyFullPageState();
}

class _FamilyFullPageState extends State<FamilyFullPage> {
  File? _familyImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sloganController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _selectedType;
  final List<String> _familyTypes = [
    'عائلة ملكية',
    'عائلة رياضية',
    'عائلة فنية',
    'عائلة ترفيهية',
    'عائلة تعليمية',
  ];

  Future<void> _pickFamilyImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _familyImage = File(pickedFile.path);
      });
    }
  }

  int _selectedTab = 0;
  String _searchQuery = '';
  final List<Map<String, String>> _topFamilies = [
    {'name': 'عائلة الملكي', 'desc': 'أقوى عائلة في التطبيق'},
    {'name': 'عائلة النجوم', 'desc': 'عائلة نشطة ومميزة'},
    {'name': 'عائلة الأبطال', 'desc': 'عائلة رياضية'},
    {'name': 'عائلة الفن', 'desc': 'عائلة فنية'},
    {'name': 'عائلة الترفيه', 'desc': 'عائلة ترفيهية'},
  ];
  final Map<String, String> _myFamily = {
    'name': 'عائلتي الملكية',
    'desc': 'هذه هي عائلتك الملكية الخاصة بك',
    'members': '12',
    'level': '5',
  };
  final List<Map<String, String>> _allFamilies = [
    {'name': 'عائلة الملكي', 'desc': 'أقوى عائلة في التطبيق'},
    {'name': 'عائلة النجوم', 'desc': 'عائلة نشطة ومميزة'},
    {'name': 'عائلة الأبطال', 'desc': 'عائلة رياضية'},
    {'name': 'عائلة الفن', 'desc': 'عائلة فنية'},
    {'name': 'عائلة الترفيه', 'desc': 'عائلة ترفيهية'},
    {'name': 'عائلة التعليم', 'desc': 'عائلة تعليمية'},
    {'name': 'عائلة المرح', 'desc': 'عائلة مرحة'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العوائل الملكية'),
        centerTitle: true,
        actions: [
          if (_selectedTab == 2)
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTab(
                  'أقوى العوائل',
                  _selectedTab == 0,
                  () => setState(() => _selectedTab = 0),
                ),
                _buildTab(
                  'عائلتي الملكية',
                  _selectedTab == 1,
                  () => setState(() => _selectedTab = 1),
                ),
                _buildTab(
                  'البحث عن عائلة',
                  _selectedTab == 2,
                  () => setState(() => _selectedTab = 2),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_selectedTab == 0) {
                  // أقوى العوائل
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _topFamilies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final fam = _topFamilies[i];
                      return _buildFamilyCard(fam['name']!, fam['desc']!);
                    },
                  );
                } else if (_selectedTab == 1) {
                  // عائلتي الملكية
                  return _buildMyFamilySection();
                } else {
                  // البحث عن عائلة
                  final results = _allFamilies
                      .where(
                        (fam) =>
                            fam['name']!.contains(_searchQuery) ||
                            fam['desc']!.contains(_searchQuery),
                      )
                      .toList();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'ابحث عن عائلة...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                      ),
                      Expanded(
                        child: results.isEmpty
                            ? Center(
                                child: Text(
                                  'لا توجد نتائج',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: results.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final fam = results[i];
                                  return _buildFamilyCard(
                                    fam['name']!,
                                    fam['desc']!,
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          // زر إنشاء عائلة
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'إنشاء عائلة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showCreateFamilyDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyCard(String name, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.amber.shade100,
            child: const Icon(Icons.groups, color: Colors.amber, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildMyFamilySection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.amber.shade100,
              child: const Icon(Icons.verified, color: Colors.amber, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              _myFamily['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _myFamily['desc']!,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatBox('المستوى', _myFamily['level']!),
                const SizedBox(width: 24),
                _buildStatBox('الأعضاء', _myFamily['members']!),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('تعديل بيانات العائلة'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showCreateFamilyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // صورة شعار العائلة
                  GestureDetector(
                    onTap: _pickFamilyImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.black,
                        backgroundImage: _familyImage != null
                            ? FileImage(_familyImage!)
                            : null,
                        child: _familyImage == null
                            ? const Icon(
                                Icons.camera_alt,
                                color: Colors.amber,
                                size: 36,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // نوع العائلة (منسدلة)
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: _familyTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                    decoration: InputDecoration(
                      labelText: 'نوع العائلة',
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // اسم العائلة
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم العائلة',
                      prefixIcon: const Icon(Icons.groups),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // شعار العائلة
                  TextField(
                    controller: _sloganController,
                    decoration: InputDecoration(
                      labelText: 'شعار العائلة',
                      prefixIcon: const Icon(Icons.emoji_events),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // وصف العائلة
                  TextField(
                    controller: _descController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'وصف العائلة',
                      prefixIcon: const Icon(Icons.description),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // TODO: تنفيذ إنشاء العائلة
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'تأسيس',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.amber),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
