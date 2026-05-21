import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/post_model.dart';
import '../../app_theme.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  final List<File> _selectedImages = [];
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  Timer? _timer;
  int _recordDuration = 0;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedVideo = null;
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedImages.clear();
        _selectedVideo = File(video.path);
      });
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path = p.join(directory.path,
          'royal_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });
      _timer = Timer.periodic(
          const Duration(seconds: 1), (t) => setState(() => _recordDuration++));
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
  }

  Future<void> _handlePost() async {
    if (_textController.text.trim().isEmpty &&
        _selectedImages.isEmpty &&
        _selectedVideo == null &&
        _audioPath == null) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userSnap = await _firestoreService.streamUserData(user.uid).first;

      List<String>? imageUrls;
      String? firstImageUrl;

      if (_selectedImages.isNotEmpty) {
        imageUrls = [];
        for (var img in _selectedImages) {
          final url = await StorageService.uploadDailyPostImage(img);
          imageUrls.add(url);
        }
        if (imageUrls.isNotEmpty) firstImageUrl = imageUrls.first;
      }

      String? videoUrl;
      if (_selectedVideo != null) {
        videoUrl = await StorageService.uploadDailyPostVideo(_selectedVideo!);
      }

      final newPost = PostModel(
        id: '',
        authorId: user.uid,
        authorName: userSnap.name,
        authorPic: userSnap.profilePic,
        content: _textController.text.trim(),
        imageUrl: firstImageUrl,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        audioUrl: _audioPath, // Assuming you handle audio upload or reference
        audioDuration: _audioPath != null ? _recordDuration : null,
        createdAt: DateTime.now(),
        isVip: userSnap.accountLevel > 5,
      );

      await _firestoreService.addPost(newPost);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Post Error: $e");
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
          title: const Text('إنشاء منشور',
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
                      onPressed: _isRecording ? null : _handlePost,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.royalGold,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('نشر',
                          style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          ],
        ),
        body: Column(
          children: [
            // Header User Info
            _buildUserInfoHeader(),

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
                            hintText: 'بماذا تفكر يا ملك؟ شاركنا لحظاتك...',
                            hintStyle:
                                TextStyle(color: Colors.white24, fontSize: 16),
                            border: InputBorder.none),
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white)),

                    const SizedBox(height: 20),
                    if (_audioPath != null) _buildAudioPreview(),
                    if (_selectedVideo != null) _buildVideoPreview(),
                    if (_selectedImages.isNotEmpty) _buildImagesGrid(),
                    const SizedBox(height: 100), // Space for tools
                  ],
                ),
              ),
            ),

            // Fixed Tools at bottom, but flexible layout
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white10,
            backgroundImage:
                user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person, color: Colors.white24)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.displayName ?? 'مستخدم ملكي',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Text('عام',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording) _buildRecordingUI(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolItem(Icons.image_rounded, 'صور', Colors.green, _pickImages),
              _toolItem(
                  Icons.videocam_rounded, 'فيديو', Colors.blue, _pickVideo),
              _toolItem(Icons.mic_rounded, 'صوت', Colors.orange,
                  _isRecording ? _stopRecording : _startRecording),
              _toolItem(Icons.tag_rounded, 'هاشتاج', Colors.purple, () {
                _textController.text += ' #';
                _textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _textController.text.length));
              }),
            ],
          ),
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
                  onPressed: () => setState(() => _selectedVideo = null)),
            )),
        const Positioned(
            bottom: 15,
            child: Text("مقطع فيديو جاهز للنشر",
                style: TextStyle(color: Colors.white70, fontSize: 12))),
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
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) => Stack(fit: StackFit.expand, children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(_selectedImages[index], fit: BoxFit.cover)),
        Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
                onTap: () => setState(() => _selectedImages.removeAt(index)),
                child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white, size: 14))))
      ]),
    );
  }

  Widget _buildAudioPreview() {
    return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
        child: Row(children: [
          const Icon(Icons.mic, color: Colors.orange),
          const SizedBox(width: 10),
          Text('تسجيل صوتي ($_recordDuration ثانية)',
              style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => setState(() => _audioPath = null))
        ]));
  }

  Widget _buildRecordingUI() {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.circle, color: Colors.red, size: 12),
            const SizedBox(width: 8),
            Text('جاري التسجيل: $_recordDuration ثانية',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ));
  }
}
