import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AudioPlayer _player = AudioPlayer();
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _countryController;
  late TextEditingController _phoneController;

  String _selectedGender = 'ذكر';
  String _selectedZodiac = 'الحمل';
  File? _imageFile;
  bool _isLoading = false;
  bool _isVoiceUploading = false;
  String? _voiceBioUrl;

  final List<String> _zodiacs = ['الحمل', 'الثور', 'الجوزاء', 'السرطان', 'الأسد', 'العذراء', 'الميزان', 'العقرب', 'القوس', 'الجدي', 'الدلو', 'الحوت'];

  @override
  void initState() {
    super.initState();
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
      });
    }
  }

  Future<void> _pickAndUploadVoice() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null) return;

    File file = File(result.files.single.path!);
    
    // التحقق من مدة الصوت
    try {
      final duration = await _player.setFilePath(file.path);
      if (duration == null) return;
      
      if (duration.inSeconds < 10 || duration.inSeconds > 15) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('يجب أن تكون مدة الصوت بين 10 و 15 ثانية فقط ⚠️'),
            backgroundColor: Colors.redAccent,
          ));
        }
        return;
      }

      setState(() => _isVoiceUploading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance.ref().child('voice_bios').child('${user.uid}.mp3');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'voiceBioUrl': url});
      setState(() {
        _voiceBioUrl = url;
        _isVoiceUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع البصمة الصوتية بنجاح 🎤 ✅')));
      }
    } catch (e) {
      setState(() => _isVoiceUploading = false);
      debugPrint("Error: $e");
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'bio': _bioController.text,
          'country': _countryController.text,
          'gender': _selectedGender,
          'zodiac': _selectedZodiac,
          'phoneNumber': _phoneController.text,
        });
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('تعديل الملف الملكي', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            _isLoading ? const Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator(strokeWidth: 2)) : 
            IconButton(onPressed: _saveProfile, icon: const Icon(Icons.check_circle, color: Colors.green, size: 28)),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(radius: 65, backgroundColor: Colors.amber.shade100, backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null, child: _imageFile == null ? const Icon(Icons.person, size: 65, color: Colors.white) : null),
                    CircleAvatar(backgroundColor: Colors.amber, radius: 20, child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18), onPressed: _pickImage)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('بصمة الصوت الملكية'),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.2))),
                child: Row(
                  children: [
                    Icon(Icons.mic, color: _voiceBioUrl != null ? Colors.green : Colors.amber, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_voiceBioUrl != null ? 'لديك بصمة صوتية مسجلة ✅' : 'لم تضف بصمة صوتية بعد', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Text('مدة الصوت المسموحة: 10-15 ثانية', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    _isVoiceUploading 
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : TextButton(onPressed: _pickAndUploadVoice, child: Text(_voiceBioUrl != null ? 'تغيير' : 'رفع الآن', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('المعلومات العامة'),
              _buildTextField(_nameController, 'الاسم المستعار', Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_bioController, 'التوقيع (Bio)', Icons.edit_note, maxLines: 2),
              const SizedBox(height: 15),
              _buildTextField(_countryController, 'الدولة', Icons.location_on_outlined),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildDropdownField('الجنس', _selectedGender, ['ذكر', 'أنثى', 'غير محدد'], (v) => setState(() => _selectedGender = v!))),
                  const SizedBox(width: 15),
                  Expanded(child: _buildDropdownField('البرج', _selectedZodiac, _zodiacs, (v) => setState(() => _selectedZodiac = v!))),
                ],
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('الاتصال'),
              _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone_android, isNumber: true),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 10, right: 5), child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey)));

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl, maxLines: maxLines, keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.amber), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: value, items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: onChanged))),
      ],
    );
  }
}
