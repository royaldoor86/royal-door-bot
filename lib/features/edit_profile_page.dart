import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/firestore_service.dart';
import '../app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';
import 'auth/enhanced_phone_verification_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AudioPlayer _player = AudioPlayer();
  late final AudioRecorder _recorder;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _countryController;
  late TextEditingController _phoneController;

  String _selectedGender = 'ذكر';
  String _selectedZodiac = 'الحمل';
  List<String> _userTags = [];
  File? _imageFile;
  bool _isLoading = false;
  bool _isVoiceUploading = false;
  String? _voiceBioUrl;
  bool _isRecording = false;
  String? _currentProfilePicUrl;

  final List<String> _zodiacs = [
    'الحمل',
    'الثور',
    'الجوزاء',
    'السرطان',
    'الأسد',
    'العذراء',
    'الميزان',
    'العقرب',
    'القوس',
    'الجدي',
    'الدلو',
    'الحوت'
  ];

  final List<String> _availableInterests = [
    '#مسلم Mosque',
    '#ملكي 👑',
    '#رويال ⚜️',
    '#فخامة ✨',
    '#سيادة 🏛️',
    '#Ludo 🎮',
    '#PUBG 🔫',
    '#FIFA ⚽',
    '#ألعاب 🕹️',
    '#برمجة 💻',
    '#غناء 🎤',
    '#رسم 🎨',
    '#موسيقى 🎵',
    '#شعر 📜',
    '#أدب 📚',
    '#صيد 🦅',
    '#خيل 🐎',
    '#رماية 🏹',
    '#سباحة 🏊',
    '#لياقة 🏋️',
    '#سفر ✈️',
    '#مغامرة 🌋',
    '#طبيعة 🌿',
    '#تصوير 📸',
    '#استكشاف 🔭',
    '#قهوة ☕',
    '#طبخ 🍳',
    '#أزياء 👔',
    '#جمال 💄',
    '#صحة 🍏',
    '#بزنس 💼',
    '#حصاد 💰',
    '#نجاح 🚀',
    '#طموح 🔝',
    '#إيجابية 🌟'
  ];

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _countryController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestoreService.streamUserData(user.uid).first;
      setState(() {
        _nameController.text = doc.name;
        _bioController.text = doc.bio;
        _countryController.text = doc.country;
        _phoneController.text = doc.phoneNumber;
        _selectedGender = doc.gender;
        _selectedZodiac = doc.zodiac.isNotEmpty ? doc.zodiac : 'الحمل';
        _voiceBioUrl = doc.voiceBioUrl;
        _currentProfilePicUrl = doc.profilePic;
        _userTags = List<String>.from(doc.tags);
      });
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_userTags.contains(tag)) {
        _userTags.remove(tag);
      } else {
        if (_userTags.length < 5) {
          _userTags.add(tag);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('يمكنك اختيار 5 اهتمامات فقط ⚠️')));
        }
      }
    });
  }

  Future<void> _pickAndUploadVoice() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;
    File file = File(path);
    try {
      final duration = await _player.setFilePath(file.path);
      if (duration == null) return;

      if (duration.inSeconds > 21) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('يجب أن تكون مدة الصوت 20 ثانية كحد أقصى 🎤 ⚠️'),
              backgroundColor: Colors.redAccent));
        }
        return;
      }

      // Validate extension (prefer common audio types)
      final ext = p.extension(file.path).toLowerCase().replaceFirst('.', '');
      const allowed = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus'];
      if (ext.isNotEmpty && !allowed.contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'نوع الملف غير مدعوم. الرجاء اختيار ملف صوتي (mp3, wav, m4a, aac).'),
              backgroundColor: Colors.redAccent));
        }
        return;
      }

      // Upload via helper (fingerprint computed there)
      setState(() => _isVoiceUploading = true);
      await _uploadVoiceFile(file, duration);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفع البصمة الصوتية بنجاح 🎤 ✅')));
      }
    } catch (e) {
      setState(() => _isVoiceUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل رفع البصمة الصوتية: $e')));
      }
    }
  }

  Future<void> _uploadVoiceFile(File file, Duration duration) async {
    setState(() => _isVoiceUploading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Validate extension
    final ext = p.extension(file.path).toLowerCase().replaceFirst('.', '');
    const allowed = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus'];
    if (ext.isNotEmpty && !allowed.contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'نوع الملف غير مدعوم. الرجاء اختيار ملف صوتي (mp3, wav, m4a, aac).'),
            backgroundColor: Colors.redAccent));
      }
      setState(() => _isVoiceUploading = false);
      return;
    }

    final bytes = await file.readAsBytes();
    final fingerprint = sha256.convert(bytes).toString();

    final String voiceFileName =
        'voice_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref =
        FirebaseStorage.instance.ref().child('voice_bios').child(voiceFileName);
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'voiceBioUrl': url,
      'voiceBioFingerprint': fingerprint,
      'voiceBioDurationSeconds': duration.inSeconds,
      'voiceBioFileSize': bytes.length,
    });

    setState(() {
      _voiceBioUrl = url;
      _isVoiceUploading = false;
    });
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (hasPermission) {
        final dir = (await getTemporaryDirectory()).path;
        final user = FirebaseAuth.instance.currentUser;
        final filePath =
            '$dir/voice_${user?.uid ?? 'anon'}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
            path: filePath);
        setState(() => _isRecording = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('يرجى منح صلاحية الميكروفون أولاً')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل بدء التسجيل: $e')));
      }
    }
  }

  Future<void> _stopRecordingAndUpload() async {
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path == null) return;
      final file = File(path);
      final duration = await _player.setFilePath(file.path);
      if (duration == null) return;
      await _uploadVoiceFile(file, duration);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفع البصمة الصوتية بنجاح 🎤 ✅')));
      }
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل إنهاء التسجيل: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String? finalImageUrl = _currentProfilePicUrl;
        if (_imageFile != null) {
          final String fileName =
              '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_pics')
              .child(fileName);
          await ref.putFile(_imageFile!);
          finalImageUrl = await ref.getDownloadURL();
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameController.text,
          'bio': _bioController.text,
          'country': _countryController.text,
          'gender': _selectedGender,
          'zodiac': _selectedZodiac,
          'phoneNumber': _phoneController.text,
          'profilePic': finalImageUrl,
          'tags': _userTags,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح ✅')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  void _showAllTagsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 25),
              const Text('مكتبة الأوسمة والوسوم الملكية',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableInterests.map((tag) {
                        bool isSelected = _userTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            _toggleTag(tag);
                            Navigator.pop(context);
                            _showAllTagsSheet();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? DesignTokens.primaryGold
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected
                                      ? DesignTokens.primaryGold
                                      : Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Text(tag,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RoyalButton(
                  label: 'إغلاق', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('تعديل الملف الملكي',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          actions: [
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(15),
                    child: RoyalLoadingIndicator(size: 20))
                : IconButton(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.check_circle,
                        color: DesignTokens.primaryGold, size: 28)),
          ],
        ),
        body: AppTheme.background(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: DesignTokens.primaryGold
                                    .withValues(alpha: 0.5),
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: DesignTokens.primaryGold
                                      .withValues(alpha: 0.2),
                                  blurRadius: 20)
                            ],
                          ),
                          child: CircleAvatar(
                              radius: 65,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.05),
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_currentProfilePicUrl != null &&
                                          _currentProfilePicUrl!.isNotEmpty
                                      ? NetworkImage(_currentProfilePicUrl!)
                                      : null) as ImageProvider?,
                              child: (_imageFile == null &&
                                      (_currentProfilePicUrl == null ||
                                          _currentProfilePicUrl!.isEmpty))
                                  ? const Icon(Icons.person,
                                      size: 65, color: Colors.white24)
                                  : null),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: DesignTokens.primaryGold,
                              shape: BoxShape.circle),
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: const Icon(Icons.camera_alt,
                                color: Colors.black, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle('الاهتمامات والوسوم الملكية (اختر 5)'),
                  GestureDetector(
                    onTap: _showAllTagsSheet,
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded,
                              color: DesignTokens.primaryGold, size: 25),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HeadingText(
                                    'افتح مكتبة الأوسمة والوسوم الملكية',
                                    fontSize: 13),
                                BodyText('انقر للاختيار من قائمة شاملة ومنظمة',
                                    fontSize: 11),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 16,
                              color: DesignTokens.primaryGold
                                  .withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _userTags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: DesignTokens.primaryGold
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: DesignTokens.primaryGold
                                          .withValues(alpha: 0.3))),
                              child: Text(tag,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: DesignTokens.primaryGold)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle('بصمة الصوت الملكية'),
                  GlassCard(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(Icons.mic,
                            color: _voiceBioUrl != null
                                ? Colors.greenAccent
                                : DesignTokens.primaryGold,
                            size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HeadingText(
                                  _voiceBioUrl != null
                                      ? 'لديك بصمة صوتية مسجلة ✅'
                                      : 'لم تضف بصمة صوتية بعد',
                                  fontSize: 13),
                              const BodyText(
                                  'مدة الصوت المسموحة: 20 ثانية كاملة',
                                  fontSize: 11),
                            ],
                          ),
                        ),
                        _isVoiceUploading
                            ? const RoyalLoadingIndicator(size: 20)
                            : GestureDetector(
                                onTap: _pickAndUploadVoice,
                                onLongPressStart: (_) => _startRecording(),
                                onLongPressEnd: (_) =>
                                    _stopRecordingAndUpload(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: Text(
                                    _isRecording
                                        ? 'جاري التسجيل... حرر للإرسال'
                                        : (_voiceBioUrl != null
                                            ? 'تغيير'
                                            : 'رفع الآن'),
                                    style: const TextStyle(
                                        color: DesignTokens.primaryGold,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle('المعلومات العامة'),
                  _buildTextField(
                      _nameController, 'الاسم المستعار', Icons.person_outline),
                  const SizedBox(height: 15),
                  _buildTextField(
                      _bioController, 'التوقيع (Bio)', Icons.edit_note,
                      maxLines: 2),
                  const SizedBox(height: 15),
                  _buildTextField(
                      _countryController, 'الدولة', Icons.location_on_outlined),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDropdownField(
                              'الجنس',
                              _selectedGender,
                              ['ذكر', 'أنثى', 'غير محدد'],
                              (v) => setState(() => _selectedGender = v!))),
                      const SizedBox(width: 15),
                      Expanded(
                          child: _buildDropdownField(
                              'البرج',
                              _selectedZodiac,
                              _zodiacs,
                              (v) => setState(() => _selectedZodiac = v!))),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle('الاتصال والتوثيق الملكي'),
                  _buildPhoneField(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    bool isVerified = _phoneController.text.isNotEmpty;
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              const Icon(Icons.phone_android,
                  color: DesignTokens.primaryGold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CaptionText('رقم الهاتف الموثق', fontSize: 11),
                    Text(
                      isVerified
                          ? _phoneController.text
                          : 'لم يتم ربط رقم هاتف بعد',
                      style: TextStyle(
                        color: isVerified
                            ? DesignTokens.neutralWhite
                            : DesignTokens.neutralWhite.withValues(alpha: 0.24),
                        fontSize: 14,
                        fontWeight:
                            isVerified ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const EnhancedPhoneVerificationPage(),
                    ),
                  );
                  if (result != null && result is String) {
                    setState(() {
                      _phoneController.text = result;
                    });
                    // تحديث فوري في الفايرستور لضمان الربط
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                        'phoneNumber': result,
                        'phoneVerified': true,
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('تم ربط وتوثيق الهاتف بنجاح 📱✅')));
                      }
                    }
                  }
                },
                child: Text(
                  isVerified ? 'تغيير' : 'ربط الآن',
                  style: const TextStyle(
                      color: DesignTokens.primaryGold,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        if (!isVerified)
          const Padding(
            padding: EdgeInsets.only(top: 8, right: 5),
            child: Text(
              '⚠️ ربط الهاتف يتيح لك الدخول لحسابك من أي جهاز بسهولة.',
              style: TextStyle(color: Colors.amberAccent, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 5),
      child: HeadingText(title,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: DesignTokens.primaryGold));

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1, bool isNumber = false}) {
    return RoyalTextField(
      controller: ctrl,
      labelText: label,
      prefixIcon: icon,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CaptionText(label, fontSize: 12),
        const SizedBox(height: 5),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              dropdownColor: DesignTokens.backgroundDarkMedium,
              style: const TextStyle(
                  color: DesignTokens.neutralWhite, fontSize: 14),
              items: items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
