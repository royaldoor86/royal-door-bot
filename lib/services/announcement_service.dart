// lib/services/announcement_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_announcement.dart';

class AnnouncementService {
  AnnouncementService._internal();
  static final AnnouncementService instance = AnnouncementService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// مسار الإعلان داخل فيربيس
  DocumentReference get _docRef =>
      _db.collection('settings').doc('app_announcement');

  /// 🔁 ستريم لمراقبة الإعلان بشكل مباشر (ريال تايم)
  Stream<AppAnnouncement?> watchAnnouncement() {
    return _docRef.snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppAnnouncement.fromDoc(snap);
    });
  }

  /// 💾 حفظ / تحديث الإعلان من لوحة التحكم
  Future<void> saveAnnouncement(AppAnnouncement ann) async {
    await _docRef.set(ann.toMap(), SetOptions(merge: true));
  }

  /// 📥 جلب الإعلان مرة واحدة (لو احتجته)
  Future<AppAnnouncement?> getAnnouncementOnce() async {
    final snap = await _docRef.get();
    if (!snap.exists) return null;
    return AppAnnouncement.fromDoc(snap);
  }
}
