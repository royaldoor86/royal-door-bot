import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceRoomBattleLogic {
  final FirebaseFirestore db;
  final String roomId;
  final Function(String) onError;
  final List<String> moderators;
  final String ownerId;
  final Map<int, Map<String, dynamic>> micSeats;
  final Function(int, int) onBattleEnded;
  final Function() onBattleTick;

  Timer? _timer;
  Map<String, dynamic>? _battleData;

  VoiceRoomBattleLogic({
    required this.db,
    required this.roomId,
    required this.onError,
    required this.moderators,
    required this.ownerId,
    required this.micSeats,
    required this.onBattleEnded,
    required this.onBattleTick,
  });

  void setBattleData(Map<String, dynamic>? data) {
    _battleData = data;
    if (data != null && data['active'] == true) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_battleData == null || _battleData!['active'] != true) {
        _stopTimer();
        return;
      }

      final endTime = (_battleData!['endTime'] as Timestamp).toDate();
      final now = DateTime.now();

      if (now.isAfter(endTime)) {
        _stopTimer();
        endBattle();
      } else {
        onBattleTick();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> endBattle({String? reason}) async {
    try {
      await db.collection('rooms').doc(roomId).update({
        'battle.active': false,
        'battle.endReason': reason ?? 'normal',
      });
    } catch (e) {
      onError('Failed to end battle: $e');
    }
  }

  void dispose() {
    _stopTimer();
  }
}
