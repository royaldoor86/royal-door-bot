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
// import '../../services/auth_service.dart';
import '../../models/post_model.dart';

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
  // final StorageService _storageService = StorageService();

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
        _selectedVideo = null; // إفراغ الفيديو عند اختيار صور
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedImages.clear(); // إفراغ الصور عند اختيار فيديو
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
        _audioPath == null) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userSnap = await _firestoreService.streamUserData(user.uid).first;

      String? imageUrl;
      if (_selectedImages.isNotEmpty)
        imageUrl =
            await StorageService.uploadDailyPostImage(_selectedImages.first);

      String? videoUrl;
      if (_selectedVideo != null)
        videoUrl = await StorageService.uploadDailyPostVideo(_selectedVideo!);

      String? audioUrl;
      // إذا كان لديك دالة uploadAudio يمكنك استخدامها هنا، أو أبقها كما هي إذا كانت غير متوفرة
      if (_audioPath != null) audioUrl = null;

      final newPost = PostModel(
        id: '',
        authorId: user.uid,
        authorName: userSnap.name,
        authorPic: userSnap.profilePic,
        content: _textController.text.trim(),
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          title: const Text('منشور ملكي جديد',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.amber)
                  : ElevatedButton(
                      onPressed: _isRecording ? null : _handlePost,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber),
                      child: const Text('نشر الآن')),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                        controller: _textController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                            hintText: 'بماذا تفكر يا ملك؟ شاركنا لحظاتك...',
                            border: InputBorder.none),
                        style: const TextStyle(fontSize: 18)),
                    if (_audioPath != null) _buildAudioPreview(),
                    const SizedBox(height: 20),
                    if (_selectedVideo != null) _buildVideoPreview(),
                    if (_selectedImages.isNotEmpty) _buildImagesGrid(),
                  ],
                ),
              ),
            ),
            if (_isRecording) _buildRecordingUI(),
            _buildBottomTools(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.black, borderRadius: BorderRadius.circular(15)),
      child: Stack(alignment: Alignment.center, children: [
        const Icon(Icons.videocam, color: Colors.white54, size: 50),
        Positioned(
            top: 10,
            right: 10,
            child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _selectedVideo = null))),
        const Text("مقطع فيديو جاهز للنشر 🎥",
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) => Stack(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(_selectedImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity)),
        Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
                onTap: () => setState(() => _selectedImages.removeAt(index)),
                child: const Icon(Icons.close, color: Colors.white, size: 18)))
      ]),
    );
  }

  Widget _buildAudioPreview() {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          const Icon(Icons.mic, color: Colors.amber),
          const SizedBox(width: 10),
          const Text('تسجيل صوتي جاهز'),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _audioPath = null))
        ]));
  }

  Widget _buildRecordingUI() {
    return Container(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text('جاري التسجيل...', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          IconButton(
              icon: const Icon(Icons.stop, color: Colors.red, size: 40),
              onPressed: _stopRecording)
        ]));
  }

  Widget _buildBottomTools() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12))),
      child: Row(children: [
        IconButton(
            icon: const Icon(Icons.image, color: Colors.green),
            onPressed: _pickImages),
        IconButton(
            icon: const Icon(Icons.videocam, color: Colors.blue),
            onPressed: _pickVideo),
        IconButton(
            icon: const Icon(Icons.mic, color: Colors.orange),
            onPressed: _isRecording ? null : _startRecording),
      ]),
    );
  }
}
