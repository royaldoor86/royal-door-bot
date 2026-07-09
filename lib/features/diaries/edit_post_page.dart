import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/post_model.dart';
import '../../app_theme.dart';

class EditPostPage extends StatefulWidget {
  final PostModel post;
  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController _textController;
  final List<dynamic> _mediaList =
      []; // Can contain String (URLs) or File (Local)
  bool _isLoading = false;
  String? _existingVideoUrl;
  File? _newVideoFile;
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.post.content);

    // Initialize media list with existing images
    if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty) {
      _mediaList.addAll(widget.post.imageUrls!);
    } else if (widget.post.imageUrl != null &&
        widget.post.imageUrl!.isNotEmpty) {
      _mediaList.add(widget.post.imageUrl!);
    }

    _existingVideoUrl = widget.post.videoUrl;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        // If we add images, we clear video to maintain post type consistency
        _newVideoFile = null;
        _existingVideoUrl = null;
        _mediaList.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _mediaList.clear();
        _newVideoFile = File(video.path);
        _existingVideoUrl = null;
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (_textController.text.trim().isEmpty &&
        _mediaList.isEmpty &&
        _newVideoFile == null &&
        _existingVideoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المنشور لا يمكن أن يكون فارغاً')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<String> finalImageUrls = [];
      String? finalVideoUrl = _existingVideoUrl;

      // Handle Images
      for (var item in _mediaList) {
        if (item is String) {
          finalImageUrls.add(item);
        } else if (item is File) {
          final url = await StorageService.uploadDailyPostImage(item);
          finalImageUrls.add(url);
        }
      }

      // Handle Video
      if (_newVideoFile != null) {
        finalVideoUrl =
            await StorageService.uploadDailyPostVideo(_newVideoFile!);
      }

      Map<String, dynamic> updateData = {
        'content': _textController.text.trim(),
        'imageUrl': finalImageUrls.isNotEmpty ? finalImageUrls.first : null,
        'imageUrls': finalImageUrls.isNotEmpty ? finalImageUrls : null,
        'videoUrl': finalVideoUrl,
        'editedAt': FieldValue.serverTimestamp(),
      };

      await _firestoreService.updatePost(widget.post.id, updateData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث المنشور بنجاح ✅')));
      }
    } catch (e) {
      debugPrint("Update Post Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء التحديث')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('تعديل المنشور',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: AppTheme.royalGold, strokeWidth: 2)))
                  : ElevatedButton(
                      onPressed: _handleUpdate,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.royalGold,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('حفظ',
                          style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TextField(
                        controller: _textController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                            hintText: 'تعديل محتوى المنشور...',
                            hintStyle:
                                TextStyle(color: Colors.white24, fontSize: 16),
                            border: InputBorder.none),
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 20),
                    if (_newVideoFile != null || _existingVideoUrl != null)
                      _buildVideoPreview(),
                    if (_mediaList.isNotEmpty) _buildImagesGrid(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.black, borderRadius: BorderRadius.circular(15)),
      child: Stack(alignment: Alignment.center, children: [
        const Icon(Icons.play_circle_fill, color: AppTheme.royalGold, size: 50),
        Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() {
                        _newVideoFile = null;
                        _existingVideoUrl = null;
                      })),
            )),
        Positioned(
            bottom: 15,
            child: Text(
                _newVideoFile != null ? "فيديو جديد جاهز" : "الفيديو الحالي",
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
      ]),
    );
  }

  Widget _buildImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 10),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: _mediaList.length,
      itemBuilder: (context, index) {
        final item = _mediaList[index];
        return Stack(fit: StackFit.expand, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item is File
                  ? Image.file(item, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: item,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.white10))),
          Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                  onTap: () => setState(() => _mediaList.removeAt(index)),
                  child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, color: Colors.white, size: 14))))
        ]);
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10, top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolItem(Icons.image_rounded, 'صور', Colors.green, _pickImages),
          _toolItem(Icons.videocam_rounded, 'فيديو', Colors.blue, _pickVideo),
          _toolItem(Icons.tag_rounded, 'هاشتاج', Colors.purple, () {
            _textController.text += ' #';
            _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length));
          }),
        ],
      ),
    );
  }

  Widget _toolItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
