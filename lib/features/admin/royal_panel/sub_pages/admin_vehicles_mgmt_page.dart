import 'package:royaldoor/theme/app_theme.dart';
import 'package:royaldoor/theme/design_tokens.dart';
import 'package:royaldoor/theme/reusable_widgets.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

class AdminVehiclesMgmtPage extends StatefulWidget {
  const AdminVehiclesMgmtPage({super.key});

  @override
  State<AdminVehiclesMgmtPage> createState() => _AdminVehiclesMgmtPageState();
}

class _AdminVehiclesMgmtPageState extends State<AdminVehiclesMgmtPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;

  void _showVehicleDialog({String? id, Map<String, dynamic>? existingData}) async {
    final nameController = TextEditingController(text: existingData?['name'] ?? "");
    final priceController = TextEditingController(text: (existingData?['price'] ?? 0).toString());
    final lottieUrlController = TextEditingController(text: existingData?['url'] ?? "");
    
    String type = existingData?['type'] ?? "gif"; 
    File? selectedFile;
    VideoPlayerController? videoController;

    if (type == "video" && lottieUrlController.text.isNotEmpty && lottieUrlController.text.startsWith('http')) {
      videoController = VideoPlayerController.networkUrl(Uri.parse(lottieUrlController.text));
      await videoController.initialize();
      if (mounted) setState(() {});
    }

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
          builder: (context, setS) => AlertDialog(
          backgroundColor: DesignTokens.backgroundDarkMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl), 
            side: BorderSide(color: DesignTokens.primaryGold.withValues(alpha: 0.3)),
          ),
          title: HeadingText(id == null ? "صناعة مركبة ملكية جديدة" : "تعديل المركبة الملكية", color: DesignTokens.primaryGold, fontSize: DesignTokens.fontSizeLg),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoyalTextField(
                  controller: nameController,
                  labelText: "اسم المركبة",
                  hintText: "أدخل اسم المركبة",
                ),
                const SizedBox(height: DesignTokens.spacingMd),
                RoyalTextField(
                  controller: priceController,
                  labelText: "السعر (نجوم ⭐)",
                  keyboardType: TextInputType.number,
                  hintText: "أدخل السعر",
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                const BodyText("نوع الملف:"),
                const SizedBox(height: DesignTokens.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
                  decoration: BoxDecoration(
                    color: DesignTokens.backgroundDarkLight,
                    borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
                  ),
                  child: DropdownButton<String>(
                    value: type,
                    isExpanded: true,
                    dropdownColor: DesignTokens.backgroundDarkMedium,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: "gif", child: BodyText("صورة متحركة GIF")),
                      DropdownMenuItem(value: "video", child: BodyText("مقطع فيديو (MP4)")),
                      DropdownMenuItem(value: "lottie", child: BodyText("رابط Lottie (JSON)")),
                    ],
                    onChanged: (v) {
                      setS(() {
                        type = v!;
                        if (type != "video") {
                          videoController?.dispose();
                          videoController = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                if (type == "lottie")
                  RoyalTextField(
                    controller: lottieUrlController,
                    labelText: "رابط JSON",
                    hintText: "أدخل رابط Lottie",
                  )
                else
                  RoyalButton(
                    onPressed: () async {
                      final XFile? file = type == "video" 
                        ? await _picker.pickVideo(source: ImageSource.gallery)
                        : await _picker.pickImage(source: ImageSource.gallery);
                        
                      if (file != null) {
                        setS(() {
                          selectedFile = File(file.path);
                          if (type == "video") {
                            videoController?.dispose();
                            videoController = VideoPlayerController.file(selectedFile!)
                              ..initialize().then((_) => setS(() {}));
                          }
                        });
                      }
                    },
                    icon: Icons.upload_file,
                    label: selectedFile == null && id != null ? "تغيير الملف الحالي" : (selectedFile == null ? "اختيار ملف" : "تم اختيار الملف ✅"),
                    height: 40,
                  ),
                if (type == "video" && videoController != null && videoController!.value.isInitialized)
                  Container(
                    margin: const EdgeInsets.only(top: DesignTokens.spacingMd),
                    height: 150, 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg), 
                      child: VideoPlayer(videoController!)
                    )
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                videoController?.dispose();
                Navigator.pop(context);
              }, 
              child: const CaptionText("إلغاء", color: DesignTokens.neutralGray400)
            ),
            SizedBox(
              width: 100,
              child: RoyalButton(
                onPressed: () => Navigator.pop(context, true),
                label: id == null ? "حفظ" : "تحديث",
                height: 36,
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && nameController.text.isNotEmpty) {
      setState(() => _isUploading = true);
      String finalUrl = type == "lottie" ? lottieUrlController.text : (existingData?['url'] ?? "");

      if (type != "lottie" && selectedFile != null) {
        final ref = _storage.ref().child('vehicles/${DateTime.now().millisecondsSinceEpoch}');
        await ref.putFile(selectedFile!);
        finalUrl = await ref.getDownloadURL();
      }

      Map<String, dynamic> vehicleData = {
        'name': nameController.text,
        'price': int.tryParse(priceController.text) ?? 0,
        'url': finalUrl,
        'type': type,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (id == null) {
        vehicleData['createdAt'] = FieldValue.serverTimestamp();
        await _db.collection('vehicles').add(vehicleData);
      } else {
        await _db.collection('vehicles').doc(id).update(vehicleData);
      }

      videoController?.dispose();
      setState(() => _isUploading = false);
    } else {
      videoController?.dispose();
    }
  }

  void _deleteVehicle(String id, String? url) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => RoyalConfirmDialog(
        title: "تأكيد الحذف",
        message: "هل أنت متأكد من حذف هذه المركبة نهائياً؟",
        onConfirm: () => Navigator.pop(ctx, true),
        confirmLabel: "حذف",
        icon: Icons.delete_forever,
        iconColor: DesignTokens.semanticError,
      ),
    );
    if (confirm == true) {
      await _db.collection('vehicles').doc(id).delete();
      if (url != null && url.contains('firebasestorage')) {
        try { await FirebaseStorage.instance.refFromURL(url).delete(); } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const HeadingText("مصنع المركبات الملكي", fontSize: DesignTokens.fontSizeLg),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppTheme.createBackgroundGradient())),
        actions: [IconButton(icon: const Icon(Icons.add_circle, color: DesignTokens.primaryGold), onPressed: () => _showVehicleDialog())],
      ),
      body: AppTheme.background(
        child: _isUploading 
          ? const RoyalLoadingIndicator(message: "جاري الرفع...")
          : StreamBuilder<QuerySnapshot>(
              stream: _db.collection('vehicles').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: BodyText("خطأ: ${snapshot.error}", color: DesignTokens.semanticError));
                if (!snapshot.hasData) return const RoyalLoadingIndicator();
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const EmptyStateWidget(icon: Icons.directions_car, title: "لا توجد مركبات حالياً", subtitle: "ابدأ بإضافة أول مركبة ملكية");

                return GridView.builder(
                  padding: const EdgeInsets.all(DesignTokens.spacingMd),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: 0.75, 
                    crossAxisSpacing: DesignTokens.spacingMd, 
                    mainAxisSpacing: DesignTokens.spacingMd
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildVehicleCard(docs[index].id, data);
                  },
                );
              },
            ),
      ),
    );
  }

  Widget _buildVehicleCard(String id, Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.neutralWhite.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl2),
        border: Border.all(color: DesignTokens.primaryGold.withValues(alpha: 0.1)),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacingXs),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl),
                child: AnimatedVehiclePreview(type: data['type'], url: data['url'])
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              color: DesignTokens.neutralBlack.withValues(alpha: 0.2), 
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(DesignTokens.borderRadiusXl2))
            ),
            child: Column(
              children: [
                BodyText(data['name'], fontWeight: DesignTokens.fontWeightBold, fontSize: DesignTokens.fontSizeXs, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: DesignTokens.spacingXs),
                CaptionText("${data['price']} 🪙", color: DesignTokens.primaryGold, fontWeight: DesignTokens.fontWeightBold),
                const SizedBox(height: DesignTokens.spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit, color: DesignTokens.primarySapphire, size: 20), 
                      onPressed: () => _showVehicleDialog(id: id, existingData: data)
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.delete, color: DesignTokens.semanticError, size: 20),
                      onPressed: () => _deleteVehicle(id, data['url'])
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedVehiclePreview extends StatefulWidget {
  final String type;
  final String url;
  const AnimatedVehiclePreview({required this.type, required this.url, super.key});

  @override
  State<AnimatedVehiclePreview> createState() => _AnimatedVehiclePreviewState();
}

class _AnimatedVehiclePreviewState extends State<AnimatedVehiclePreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (widget.type == "video") {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          _controller!.setLooping(true);
          _controller!.setVolume(0); 
          _controller!.play();
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void didUpdateWidget(AnimatedVehiclePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.type != widget.type) {
      _controller?.dispose();
      _controller = null;
      _initController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == "lottie") {
      return Lottie.network(
        widget.url, 
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
      );
    }
    if (widget.type == "gif") {
      return Image.network(
        widget.url, 
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white10),
      );
    }
    if (widget.type == "video" && _controller != null && _controller!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }
    return const Center(child: Icon(Icons.directions_car, color: Colors.white10, size: 50));
  }
}
