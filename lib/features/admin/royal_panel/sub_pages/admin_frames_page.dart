import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/frame_model.dart';
import '../../../../services/storage_service.dart';

class AdminFramesPage extends StatefulWidget {
  const AdminFramesPage({Key? key}) : super(key: key);

  @override
  State<AdminFramesPage> createState() => _AdminFramesPageState();
}

class _AdminFramesPageState extends State<AdminFramesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryEmerald = const Color(0xFF042F2C);
  final Color accentGold = const Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF021412),
        appBar: AppBar(
          backgroundColor: primaryEmerald,
          elevation: 0,
          title: Text('إدارة الإطارات الملكية', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildAddHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('frames').orderBy('isActive', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return _buildEmptyState();

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final frame = FrameModel.fromFirestore(docs[index] as DocumentSnapshot<Map<String, dynamic>>);
                      return _buildFrameCard(frame);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryEmerald,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showAddFrameDialog(),
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.black),
        label: const Text('إضافة إطار ملكي جديد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildFrameCard(FrameModel frame) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentGold.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentGold.withOpacity(0.2), width: 1),
                    ),
                    child: ClipOval(
                      child: Image.network(frame.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: accentGold.withOpacity(0.3))),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(frame.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${frame.price} 🪙', style: TextStyle(color: accentGold, fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (frame.isAnimated) Icon(Icons.auto_awesome, color: Colors.pinkAccent, size: 14),
                    if (frame.isFamilyFrame) Icon(Icons.castle, color: Colors.cyanAccent, size: 14),
                    if (frame.minVipLevel != null) Text(' VIP ${frame.minVipLevel}', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 5, right: 5,
            child: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
              onPressed: () => _db.collection('frames').doc(frame.id).delete(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFrameDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    File? selectedFile;
    bool isAnimated = false;
    bool isProfileFrame = true;
    bool isFamilyFrame = false;
    int vipLevel = 0;
    String format = 'png';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: accentGold.withOpacity(0.3))),
          title: Text('تخصيon إطار ملكي', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final XFile? img = await picker.pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        setModalState(() => selectedFile = File(img.path));
                      }
                    },
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(color: accentGold, width: 1.5),
                        image: selectedFile != null ? DecorationImage(image: FileImage(selectedFile!), fit: BoxFit.cover) : null,
                      ),
                      child: selectedFile == null ? Icon(Icons.add_a_photo_rounded, color: accentGold, size: 35) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('اسم الإطار'),
                _buildRoyalTextField(nameCtrl, 'مثال: إطار التنين الذهبي', Icons.edit),
                const SizedBox(height: 15),
                _buildFieldLabel('السعر بالكوينز'),
                _buildRoyalTextField(priceCtrl, '0', Icons.monetization_on, isNumber: true),
                const SizedBox(height: 15),
                _buildFieldLabel('رابط مباشر (اختياري)'),
                _buildRoyalTextField(linkCtrl, 'https://...', Icons.link),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                _buildOptionRow('إطار متحرك', isAnimated, (v) => setModalState(() => isAnimated = v)),
                _buildOptionRow('إطار بروفايل', isProfileFrame, (v) => setModalState(() => isProfileFrame = v)),
                _buildOptionRow('إطار عائلة', isFamilyFrame, (v) => setModalState(() => isFamilyFrame = v)),
                const SizedBox(height: 10),
                Text('مستوى VIP الأدنى: $vipLevel', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Slider(
                  value: vipLevel.toDouble(),
                  min: 0, max: 10, divisions: 10,
                  activeColor: accentGold,
                  onChanged: (v) => setModalState(() => vipLevel = v.toInt()),
                ),
                const SizedBox(height: 10),
                _buildFieldLabel('صيغة الملف'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['png', 'gif', 'webp'].map((f) => ChoiceChip(
                    label: Text(f), selected: format == f,
                    onSelected: (s) => setModalState(() => format = f),
                    selectedColor: accentGold,
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
            if (isLoading) const CircularProgressIndicator()
            else ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || (selectedFile == null && linkCtrl.text.isEmpty)) return;
                setModalState(() => isLoading = true);
                try {
                  String finalUrl = linkCtrl.text;
                  if (selectedFile != null) {
                    finalUrl = await StorageService.uploadAvatarFrame(nameCtrl.text, selectedFile!);
                  }
                  await _db.collection('frames').add({
                    'name': nameCtrl.text.trim(),
                    'imageUrl': finalUrl,
                    'price': int.parse(priceCtrl.text),
                    'isAnimated': isAnimated,
                    'isProfileFrame': isProfileFrame,
                    'isFamilyFrame': isFamilyFrame,
                    'minVipLevel': vipLevel,
                    'format': format,
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                } finally {
                  setModalState(() => isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: Colors.black),
              child: const Text('حفظ ونشر الإطار', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, right: 5), child: Text(text, style: TextStyle(color: accentGold.withOpacity(0.7), fontSize: 12)));

  Widget _buildRoyalTextField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: accentGold, size: 20),
        filled: true, fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildOptionRow(String title, bool val, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Switch(value: val, onChanged: onChanged, activeColor: accentGold),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_pin_circle_outlined, size: 80, color: accentGold.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('لا توجد إطارات ملكية مضافة', style: TextStyle(color: Colors.white24, fontSize: 16)),
        ],
      ),
    );
  }
}
