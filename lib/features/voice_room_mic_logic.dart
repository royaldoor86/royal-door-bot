import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/agora_service.dart';

class VoiceRoomMicLogic {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final AgoraService agoraService;
  final String roomId;
  final String ownerId;
  final List<String> admins; // إضافة قائمة المسؤولين
  final List<String> moderators;
  final Map<String, dynamic> moderatorPermissions;
  final int maxSeats;
  final bool adminOnlyMic;
  final bool requireMicApproval; // إضافة هذا الحقل
  final List<int> lockedSeats;
  final Function(String) onError;
  final Function(int) onSeatTaken;
  final Function() onSeatLeft;
  final Function() onRequestMic; // إضافة رد فعل لطلب المايك

  VoiceRoomMicLogic({
    required this.db,
    required this.auth,
    required this.agoraService,
    required this.roomId,
    required this.ownerId,
    required this.admins, // إضافة هنا
    required this.moderators,
    required this.moderatorPermissions,
    required this.maxSeats,
    required this.adminOnlyMic,
    required this.requireMicApproval,
    required this.lockedSeats,
    required this.onError,
    required this.onSeatTaken,
    required this.onSeatLeft,
    required this.onRequestMic,
  });

  Future<void> takeMic(int seatNumber, int? currentSeat) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        onError('يجب تسجيل الدخول أولاً');
        return;
      }

      // التحقق من الصلاحيات: صاحب الغرفة أو مسؤول أو مشرف
      bool isAdmin = admins.contains(user.uid);
      bool isOwnerOrAdmin = user.uid == ownerId || isAdmin;
      bool isOwnerOrAdminOrMod = isOwnerOrAdmin || moderators.contains(user.uid);

      // إذا كانت الغرفة تتطلب موافقة والمستخدم ليس صاحب الغرفة أو مسؤولاً
      // تم استثناء المسؤول وصاحب الغرفة فقط من طلب المايك بناءً على الطلب رقم 4
      if (requireMicApproval && !isOwnerOrAdmin) {
        onRequestMic();
        return;
      }

      // التحقق من القفل
      if (lockedSeats.contains(seatNumber)) {
        bool canManage = isOwnerOrAdminOrMod && (moderatorPermissions['canManageMic'] ?? false);
        if (!canManage) {
          onError('هذا المايك مغلق حالياً 🔒');
          return;
        }
      }

      // التحقق من نمط الإدارة فقط
      if (adminOnlyMic && !isOwnerOrAdminOrMod) {
        onError('الصعود للمايك متاح للمشرفين فقط 🛡️');
        return;
      }

      // إذا كان المستخدم على مايك آخر، يتركه أولاً
      if (currentSeat != null) {
        await leaveMic(currentSeat);
      }

      // جلب بيانات المستخدم لتخزينها في مقعد المايك (للسرعة في العرض)
      final userDoc = await db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // تحديث قاعدة البيانات في المجموعة الفرعية mic_seats
      await db
          .collection('rooms')
          .doc(roomId)
          .collection('mic_seats')
          .doc(seatNumber.toString())
          .set({
        'userId': user.uid,
        'name': userData['name'] ?? user.displayName ?? 'مستخدم ملكي',
        'photoUrl': userData['profilePic'] ?? user.photoURL ?? '',
        'micFrame': userData['currentMicFrame'] ?? '',
        'joinedAt': FieldValue.serverTimestamp(),
        'isMuted': false,
        'agoraUid': agoraService.localUid ?? 0, // تخزين المعرف الحقيقي
      });

      // تحويل الدور في أكورا إلى متحدث (Broadcaster)
      await agoraService.updateClientRole(true);

      onSeatTaken(seatNumber);
    } catch (e) {
      onError('فشل الصعود للمايك: $e');
    }
  }

  Future<void> leaveMic(int? seatNumber) async {
    try {
      if (seatNumber == null) return;

      // حذف بيانات المايك من المجموعة الفرعية
      await db
          .collection('rooms')
          .doc(roomId)
          .collection('mic_seats')
          .doc(seatNumber.toString())
          .delete();

      // تحويل الدور في أكورا إلى مستمع (Audience) لتوفير التكلفة
      await agoraService.updateClientRole(false);

      onSeatLeft();
    } catch (e) {
      onError('فشل مغادرة المايك: $e');
    }
  }

  void dispose() {
  }
}
