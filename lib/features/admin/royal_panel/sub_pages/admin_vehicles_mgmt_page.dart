import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

class AdminVehiclesMgmtPage extends StatefulWidget {
  const AdminVehiclesMgmtPage({Key? key}) : super(key: key);

  @override
  State<AdminVehiclesMgmtPage> createState() => _AdminVehiclesMgmtPageState();
}

class _AdminVehiclesMgmtPageState extends State<AdminVehiclesMgmtPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;

  void _addNewVehicle() async {
    String name = "";
    int price = 0;
    String type = "gif"; // gif, video, lottie
    File? selectedFile;
    String lottieUrl = "";
    VideoPlayerController? videoController;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          backgroundColor: const Color(0xFF042F2C),
          title: const Text("صناعة مركبة ملكية جديدة", style: TextStyle(color: Colors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "اسم المركبة", labelStyle: TextStyle(color: Colors.white70)),
                  onChanged: (v) => name = v,
                ),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "السعر (كوينز)", labelStyle: TextStyle(color: Colors.white70)),
                  onChanged: (v) => price = int.tryParse(v) ?? 0,
                ),
                const SizedBox(height: 20),
                const Text("نوع الملف:", style: TextStyle(color: Colors.white)),
                DropdownButton<String>(
                  value: type,
                  dropdownColor: Colors.black,
                  items: const [
                    DropdownMenuItem(value: "gif", child: Text("صورة متحركة GIF", style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: "video", child: Text("مقطع فيديو (MP4)", style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: "lottie", child: Text("رابط Lottie (JSON)", style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) => setS(() => type = v!),
                ),
                const SizedBox(height: 20),
                if (type == "lottie")
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "رابط JSON", labelStyle: TextStyle(color: Colors.white70)),
                    onChanged: (v) => lottieUrl = v,
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
                      if (file != null) {
                        setS(() {
                          selectedFile = File(file.path);
                          if (type == "video") {
                            videoController = VideoPlayerController.file(selectedFile!)..initialize().then((_) => setS(() {}));
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: Text(selectedFile == null ? "اختيار ملف من الاستوديو" : "تم اختيار الملف ✅"),
                  ),
                if (videoController != null && videoController!.value.isInitialized)
                  SizedBox(height: 150, child: VideoPlayer(videoController!)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text("حفظ وصناعة", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      if (confirmed == true && name.isNotEmpty) {
        setState(() => _isUploading = true);
        String finalUrl = lottieUrl;

        if (type != "lottie" && selectedFile != null) {
          final ref = _storage.ref().child('vehicles/${DateTime.now().millisecondsSinceEpoch}');
          await ref.putFile(selectedFile!);
          finalUrl = await ref.getDownloadURL();
        }

        await _db.collection('vehicles').add({
          'name': name,
          'price': price,
          'url': finalUrl,
          'type': type,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isUploading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021412),
      appBar: AppBar(
        title: const Text("مصنع المركبات الملكي"),
        backgroundColor: const Color(0xFF042F2C),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle, color: Colors.amber), onPressed: _addNewVehicle)
        ],
      ),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : StreamBuilder<QuerySnapshot>(
            stream: _db.collection('vehicles').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 15, mainAxisSpacing: 15),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildVehicleCard(docs[index].id, data);
                },
              );
            },
          ),
    );
  }

  Widget _buildVehicleCard(String id, Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Expanded(
            child: _buildPreview(data['type'], data['url']),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(data['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${data['price']} 🪙", style: const TextStyle(color: Colors.amber, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                  onPressed: () => _db.collection('vehicles').doc(id).delete(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(String type, String url) {
    if (type == "lottie") return Lottie.network(url);
    if (type == "gif") return Image.network(url);
    if (type == "video") return const Icon(Icons.videocam, color: Colors.amber, size: 50);
    return const Icon(Icons.directions_car, color: Colors.white24);
  }
}
