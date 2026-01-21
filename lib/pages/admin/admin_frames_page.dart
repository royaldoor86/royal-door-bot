import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/frame_model.dart';
import '../../services/storage_service.dart';

class AdminFramesPage extends StatefulWidget {
  const AdminFramesPage({super.key});

  @override
  State<AdminFramesPage> createState() => _AdminFramesPageState();
}

class _AdminFramesPageState extends State<AdminFramesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isSeeding = false;
  List<Map<String, dynamic>> _vipRanks = [];

  @override
  void initState() {
    super.initState();
    _loadVipRanks();
  }

  Future<void> _loadVipRanks() async {
    try {
      final snap = await _db
          .collection('vip_ranks')
          .orderBy('level', descending: true)
          .get();
      setState(() {
        _vipRanks =
            snap.docs.map((d) => {'id': d.id, ...d.data() ?? {}}).toList();
      });
    } catch (_) {}
  }

  // دالة لإضافة مجموعة من الإطارات الملكية فوراً بروابط مضمونة
  Future<void> _seedFrames() async {
    setState(() => _isSeeding = true);
    try {
      // روابط مباشرة لإطارات احترافية شفافة
      final frames = [
        {
          'name': 'الذهب الملكي 👑',
          'price': 5000,
          'url': 'https://i.ibb.co/mS0cyvX/frame-gold.png'
        },
        {
          'name': 'تنين النار 🔥',
          'price': 8000,
          'url': 'https://i.ibb.co/vX8ZzYm/frame-fire.png'
        },
        {
          'name': 'الألماس المتوهج 💎',
          'price': 15000,
          'url': 'https://i.ibb.co/pY8ZzYm/frame-diamond.png'
        },
        {
          'name': 'إطار الفارس ⚔️',
          'price': 10000,
          'url': 'https://i.ibb.co/BX8ZzYm/frame-knight.png'
        },
        {
          'name': 'رائد الفضاء 🚀',
          'price': 4000,
          'url': 'https://i.ibb.co/mX8ZzYm/frame-space.png'
        },
        {
          'name': 'الأسد الشجاع 🦁',
          'price': 12000,
          'url': 'https://i.ibb.co/VWVmY8m/frame-lion.png'
        },
      ];

      // حذف الإطارات القديمة المعطلة أولاً لتنظيف القائمة
      final oldFrames = await _db.collection('avatar_frames').get();
      for (var doc in oldFrames.docs) {
        await doc.reference.delete();
      }

      for (var f in frames) {
        await _db.collection('avatar_frames').add({
          'name': f['name'],
          'price': f['price'],
          'imageUrl': f['url'],
          'isActive': true,
          'onSale': false,
          'salePrice': 0,
          'isFamilyFrame': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("تم تحديث الإطارات الملكية بنجاح! ✅")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("خطأ أثناء التحديث: $e")));
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  void _showAddFrameDialog({FrameModel? frame}) {
    final nameCtrl = TextEditingController(text: frame?.name);
    final priceCtrl = TextEditingController(text: frame?.price.toString());
    File? selectedFile;
    final urlCtrl = TextEditingController(text: frame?.imageUrl);
    bool isFamily = false;
    bool isUploading = false;
    bool isAnimated = (frame?.isAnimated ?? false);
    String sourceType = frame != null
        ? (frame.sourceType ?? 'upload')
        : 'upload'; // 'upload' or 'link'
    String? visibleForVip = frame?.visibleForVip ?? null;
    bool isProfileFrame = frame?.isProfileFrame ?? false;
    String mediaKind = 'image'; // 'image' or 'video' when uploading

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setST) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A0A10),
            title: Text(frame == null ? "إضافة إطار جديد" : "تعديل إطار",
                style: const TextStyle(color: Colors.amber)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      // allow picking image or video depending on mediaKind
                      final picker = ImagePicker();
                      XFile? picked;
                      if (mediaKind == 'image')
                        picked =
                            await picker.pickImage(source: ImageSource.gallery);
                      else
                        picked =
                            await picker.pickVideo(source: ImageSource.gallery);
                      if (picked != null)
                        setST(() => selectedFile = File(picked!.path));
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.5))),
                      child: selectedFile != null
                          ? (mediaKind == 'image'
                              ? Image.file(selectedFile!, fit: BoxFit.contain)
                              : const Icon(Icons.movie,
                                  color: Colors.amber, size: 48))
                          : (frame != null
                              ? CachedNetworkImage(
                                  imageUrl: frame.imageUrl, fit: BoxFit.contain)
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Icon(Icons.add_photo_alternate,
                                          color: Colors.amber, size: 40),
                                      Text("اختر إطار",
                                          style: TextStyle(
                                              color: Colors.white24,
                                              fontSize: 10))
                                    ])),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Source type: upload or link
                  Row(children: [
                    Expanded(
                      child: RadioListTile<String>(
                          value: 'upload',
                          groupValue: sourceType,
                          title: const Text('رفع ملف',
                              style: TextStyle(color: Colors.white70)),
                          activeColor: Colors.amber,
                          onChanged: (v) => setST(() => sourceType = v!)),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                          value: 'link',
                          groupValue: sourceType,
                          title: const Text('رابط مباشر',
                              style: TextStyle(color: Colors.white70)),
                          activeColor: Colors.amber,
                          onChanged: (v) => setST(() => sourceType = v!)),
                    ),
                  ]),
                  if (sourceType == 'upload')
                    Row(children: [
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () => setST(() => mediaKind = 'image'),
                              icon: const Icon(Icons.image),
                              label: const Text('صورة'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () => setST(() => mediaKind = 'video'),
                              icon: const Icon(Icons.movie),
                              label: const Text('فيديو'))),
                    ])
                  else
                    _adminField(
                        urlCtrl, 'رابط الملف (PNG/JPG/GIF/MP4)', Icons.link),
                  const SizedBox(height: 20),
                  _adminField(nameCtrl, "اسم الإطار", Icons.branding_watermark),
                  const SizedBox(height: 12),
                  _adminField(priceCtrl, "السعر (جواهر)", Icons.diamond,
                      isNumber: true),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text("إطار متحرك (MP4/GIF)",
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    value: isAnimated,
                    onChanged: (v) => setST(() => isAnimated = v ?? false),
                    activeColor: Colors.amber,
                    checkColor: Colors.black,
                  ),
                  const SizedBox(height: 8),
                  // VIP visibility selector
                  DropdownButtonFormField<String>(
                    value: visibleForVip,
                    decoration: InputDecoration(
                        labelText: 'مرئي للـ VIP (اختياري)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('الكل')),
                      ..._vipRanks.map((r) => DropdownMenuItem(
                          value: r['name'] ?? r['id'],
                          child: Text(r['name'] ?? r['id']))),
                    ],
                    onChanged: (v) => setST(() => visibleForVip = v),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text("إطار خاص بالعائلات فقط",
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    value: isFamily,
                    onChanged: (v) => setST(() => isFamily = v ?? false),
                    activeColor: Colors.amber,
                    checkColor: Colors.black,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text(
                        "إطار بروفايل (يظهر في صفحة إطارات البروفايل)",
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    value: isProfileFrame,
                    onChanged: (v) => setST(() => isProfileFrame = v ?? false),
                    activeColor: Colors.amber,
                    checkColor: Colors.black,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("إلغاء")),
              if (isUploading)
                const CircularProgressIndicator(color: Colors.amber)
              else
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty ||
                        (frame == null &&
                            selectedFile == null &&
                            sourceType == 'upload')) return;
                    if (sourceType == 'link' && urlCtrl.text.isEmpty) return;

                    setST(() => isUploading = true);
                    try {
                      String finalUrl = frame?.imageUrl ?? '';
                      if (sourceType == 'upload' && selectedFile != null) {
                        finalUrl = await StorageService.uploadAvatarFrame(
                            nameCtrl.text, selectedFile!);
                      } else if (sourceType == 'link') {
                        finalUrl = urlCtrl.text.trim();
                      }

                      final data = {
                        'name': nameCtrl.text,
                        'imageUrl': finalUrl,
                        'price': int.tryParse(priceCtrl.text) ?? 0,
                        'isFamilyFrame': isFamily,
                        'isActive': true,
                        'isAnimated': isAnimated,
                        'sourceType': sourceType,
                        'visibleForVip': visibleForVip,
                        'isProfileFrame': isProfileFrame,
                        'createdAt': FieldValue.serverTimestamp(),
                      };

                      if (frame == null) {
                        await _db.collection('avatar_frames').add(data);
                      } else {
                        await _db
                            .collection('avatar_frames')
                            .doc(frame.id)
                            .update(data);
                      }
                      if (mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text("خطأ: $e")));
                    } finally {
                      setST(() => isUploading = false);
                    }
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child:
                      const Text("حفظ", style: TextStyle(color: Colors.black)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("إدارة الإطارات 🖼️",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Row(
              children: [
                if (_isSeeding)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.amber))
                else
                  IconButton(
                    icon: const Icon(Icons.auto_fix_high,
                        color: Colors.cyanAccent),
                    onPressed: _seedFrames,
                    tooltip: "تحديث الإطارات فوراً",
                  ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showAddFrameDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("إضافة"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('avatar_frames').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("لا توجد إطارات متوفرة",
                          style: TextStyle(color: Colors.white38)),
                      const SizedBox(height: 10),
                      TextButton(
                          onPressed: _seedFrames,
                          child: const Text("اضغط هنا لتنزيل الإطارات الملكية",
                              style: TextStyle(color: Colors.amber))),
                    ],
                  ),
                );
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final frame = FrameModel.fromFirestore(
                      docs[index] as DocumentSnapshot<Map<String, dynamic>>);
                  final bool isFamily = (docs[index].data()
                          as Map<String, dynamic>)['isFamilyFrame'] ??
                      false;

                  return _adminFrameCard(frame, isFamily);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _adminFrameCard(FrameModel frame, bool isFamily) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color:
                  isFamily ? Colors.amber.withOpacity(0.3) : Colors.white10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const CircleAvatar(radius: 30, backgroundColor: Colors.white10),
              CachedNetworkImage(
                imageUrl: frame.imageUrl,
                width: 75,
                height: 75,
                fit: BoxFit.contain,
                placeholder: (c, u) =>
                    const CircularProgressIndicator(strokeWidth: 1),
                errorWidget: (c, u, e) => const Icon(Icons.image_not_supported,
                    color: Colors.white24),
              ),
              if ((frame.visibleForVip ?? '') != '')
                Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(frame.visibleForVip ?? '',
                            style: const TextStyle(
                                color: Colors.amber, fontSize: 10)))),
              if (frame.isProfileFrame)
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('بروفايل',
                            style: const TextStyle(
                                color: Colors.cyan, fontSize: 10)))),
              if (isFamily)
                const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.shield, color: Colors.amber, size: 20)),
            ],
          ),
          const SizedBox(height: 10),
          Text(frame.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          Text("${frame.price} 💎",
              style: const TextStyle(color: Colors.amber, fontSize: 11)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: () => _showAddFrameDialog(frame: frame)),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                onPressed: () =>
                    _db.collection('avatar_frames').doc(frame.id).delete(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminField(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.amber, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}
