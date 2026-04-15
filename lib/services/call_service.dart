import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../features/chat/call_page.dart';
import '../widgets/incoming_call_overlay.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  StreamSubscription<QuerySnapshot>? _callSubscription;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  OverlayEntry? _overlayEntry;

  void startListening(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _callSubscription?.cancel();
    _callSubscription = _db
        .collection('calls')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final callData = snapshot.docs.first.data() as Map<String, dynamic>;
        final callId = snapshot.docs.first.id;

        // التحقق مما إذا كان المستخدم في مكالمة حالياً
        if (CallPage.isCallActive) {
          _db.collection('calls').doc(callId).update({'status': 'busy'});
          return;
        }

        _showIncomingCallOverlay(context, callData, callId);
      } else {
        _hideIncomingCallOverlay();
      }
    });
  }

  void _showIncomingCallOverlay(BuildContext context, Map<String, dynamic> callData, String callId) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => IncomingCallOverlay(
        callData: callData,
        callId: callId,
        onAccept: () => _acceptCall(context, callData, callId),
        onDecline: () => _declineCall(callId),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideIncomingCallOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _acceptCall(BuildContext context, Map<String, dynamic> callData, String callId) async {
    _hideIncomingCallOverlay();
    await _db.collection('calls').doc(callId).update({'status': 'accepted'});
    
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            channelName: callData['channelName'],
            userId: callData['receiverId'],
            otherUserId: callData['callerId'],
            isVideoCall: callData['type'] == 'video',
            callId: callId,
          ),
        ),
      );
    }
  }

  void _declineCall(String callId) async {
    _hideIncomingCallOverlay();
    await _db.collection('calls').doc(callId).update({'status': 'declined'});
  }

  void stopListening() {
    _callSubscription?.cancel();
    _hideIncomingCallOverlay();
  }
}
