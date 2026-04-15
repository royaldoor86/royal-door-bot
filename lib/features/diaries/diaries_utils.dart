import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../../app_theme.dart';

String formatPostDate(DateTime dt) {
  try {
    final now = DateTime.now();
    final localDt = dt.toLocal();
    final diff = now.difference(localDt);

    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      if (m == 1) return 'منذ دقيقة';
      if (m == 2) return 'منذ دقيقتين';
      return 'منذ $m دقائق';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      if (h == 1) return 'منذ ساعة';
      if (h == 2) return 'منذ ساعتين';
      return 'منذ $h ساعات';
    }

    final today = DateTime(now.year, now.month, now.day);
    final dDate = DateTime(localDt.year, localDt.month, localDt.day);
    final days = today.difference(dDate).inDays;
    if (days == 1) return 'أمس • ${DateFormat('HH:mm', 'ar').format(localDt)}';
    if (days < 7) return '${DateFormat.EEEE('ar').format(localDt)} • ${DateFormat('HH:mm', 'ar').format(localDt)}';
    return DateFormat('d MMMM yyyy • HH:mm', 'ar').format(localDt);
  } catch (e) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }
}

Future<void> downloadMedia(BuildContext context, String url, {required bool isImage}) async {
  try {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
       // On Android 13+, we might need photo/video permissions
       if (Platform.isAndroid) {
         await Permission.photos.request();
         await Permission.videos.request();
       }
    }

    final uri = Uri.parse(url);
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to download');

    final dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${dir!.path}/RoyalDur');
    if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);
    
    final ext = uri.path.split('.').last.split('?').first;
    final name = '${isImage ? 'IMG' : 'VID'}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = File('${downloadsDir.path}/$name');
    await file.writeAsBytes(res.bodyBytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحفظ في: ${file.path}')));
    }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل التنزيل')));
  }
}

Future<void> sharePostWithMedia(BuildContext context, PostModel post) async {
  final link = 'https://royaldur.app/post/${post.id}';
  try {
    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
      final res = await http.get(Uri.parse(post.imageUrl!));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/share_${post.id}.jpg');
      await file.writeAsBytes(res.bodyBytes);
      await Share.shareXFiles([XFile(file.path)], text: '${post.content}\n$link');
    } else {
      await Share.share('${post.content}\n$link');
    }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل المشاركة')));
  }
}

void openCommentsSheet(BuildContext context, PostModel post) {
  final FirestoreService firestoreService = FirestoreService();
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final TextEditingController controller = TextEditingController();
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const Padding(padding: EdgeInsets.all(16), child: Text('التعليقات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: firestoreService.streamPostComments(post.id),
                  builder: (c, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final comments = snap.data!;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final cm = comments[i];
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(cm['userPic'] ?? '')),
                          title: Text(cm['userName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(cm['text'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 8, right: 8, top: 8),
                child: Row(children: [
                  Expanded(child: TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'اكتب تعليقاً...', hintStyle: const TextStyle(color: Colors.white24), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)))),
                  IconButton(icon: const Icon(Icons.send, color: AppTheme.royalGold), onPressed: () async {
                    if (controller.text.trim().isEmpty) return;
                    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final user = await firestoreService.streamUserData(uid).first;
                    await firestoreService.addPostComment(post.id, uid, user.name, user.profilePic, controller.text.trim());
                    controller.clear();
                  })
                ]),
              ),
              const SizedBox(height: 10),
            ]),
          ),
        );
      });
}

class ImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? postText;
  const ImageViewer({super.key, required this.imageUrl, this.postText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
