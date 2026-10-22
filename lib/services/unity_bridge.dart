import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'acoura_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UnityBridge {
  static const MethodChannel _channel = MethodChannel('com.royaldoor.unity');
  static UnityBridge? _instance;

  final Map<String, Function(Map<String, dynamic>)> _callbacks = {};
  final ValueNotifier<int?> pointsBalance = ValueNotifier<int?>(null);
  final _roomCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _roomJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _roomFailedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gameFinishedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _closeUnityController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _backToGamesController =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _pointsSubscription;
  bool _initialized = false;
  bool _unityReady = false;
  Map<String, dynamic>? _pendingPlayerInfo;

  final Set<String> _processedMatchIds = {};

  @visibleForTesting
  Set<String> get processedMatchIdsForTesting => _processedMatchIds;

  UnityBridge._();

  static UnityBridge get instance => _instance ??= UnityBridge._();

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onUnityMessage' && call.arguments is String) {
        onUnityMessage(call.arguments as String);
      }
    });
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_watchUserPoints);
    _watchUserPoints(FirebaseAuth.instance.currentUser);
  }

  void _watchUserPoints(User? user) {
    _pointsSubscription?.cancel();
    _pointsSubscription = null;
    if (user == null) {
      pointsBalance.value = null;
      if (_unityReady) unawaited(sendPlayerInfoToUnity());
      return;
    }
    _pointsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      final userData = snapshot.data() ?? <String, dynamic>{};
      final rawPoints = userData['points'];
      if (rawPoints is num && rawPoints.isFinite) {
        pointsBalance.value = rawPoints.toInt();
      }
      if (_unityReady) unawaited(sendPlayerInfoToUnity());
    }, onError: (Object error) {
      debugPrint('Unity balance listener failed: $error');
    });
  }

  Future<void> sendMessageToUnity({
    required String target,
    required String method,
    required String message,
  }) async {
    await initialize();
    await _sendUnityMessage(target, method, message);
  }

  void cachePlayerInfo({
    required String name,
    required String imageUrl,
    required int points,
  }) {
    _pendingPlayerInfo = {
      'name': name,
      'imageUrl': imageUrl,
      'points': points,
    };
  }

  // إرسال بيانات اللاعب إلى Unity بعد إنشاء Controller
  Future<void> sendPlayerInfoToUnity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user logged in, cannot send player info to Unity');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? <String, dynamic>{};

      final name = userData['name'] ?? userData['displayName'] ?? user.displayName ?? 'Player';
      final photoUrl = userData['profilePic'] ?? userData['avatarUrl'] ?? userData['photoUrl'] ?? user.photoURL ?? '';
      final points = userData['points'] is num ? (userData['points'] as num).toInt() : 0;

      final message = jsonEncode({
        'name': name,
        'imageUrl': photoUrl,
        'points': points,
      });

      await _sendUnityMessage('PlayerInfoManager', 'SetPlayerInfoFromFlutter', message);
      debugPrint('Sent player info to Unity: $message');
    } catch (e) {
      debugPrint('Failed to send player info to Unity: $e');
    }
  }

  Future<bool> _sendUnityMessage(
      String target, String method, String message) async {
    try {
      return await _channel.invokeMethod<bool>('sendUnityMessage', {
            'target': target,
            'method': method,
            'message': message,
          }) ??
          false;
    } on PlatformException catch (error) {
      debugPrint('Could not send message to Unity: ${error.message}');
      return false;
    }
  }

  Future<void> _closeUnityActivity() async {
    try {
      await _channel.invokeMethod<bool>('closeUnityGame');
    } on PlatformException catch (error) {
      debugPrint('Could not close Unity activity: ${error.message}');
    }
  }

  void onUnityMessage(String rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('Ignoring Unity message: expected a JSON object');
        return;
      }

      final type = (decoded['type'] ?? decoded['action']) as String?;
      if (type is! String || type.isEmpty) {
        debugPrint('Ignoring Unity message without a type');
        return;
      }

      debugPrint('UnityBridge: Received message from Unity - type: $type');
      _callbacks[type]?.call(decoded);

      switch (type) {
        case 'UnityReady':
          _unityReady = true;
          unawaited(sendPlayerInfoToUnity());
          break;
        case 'EntryPointsRequested':
          unawaited(_handleEntryPointsRequest(decoded));
          break;
        case 'EntryPointsRefundRequested':
          unawaited(_handleRefund(decoded));
          break;
        case 'PlayerWon':
          unawaited(_handleMatchResult(decoded, 'win'));
          break;
        case 'PlayerLost':
          unawaited(_handleMatchResult(decoded, 'loss'));
          break;
        case 'BackToGamesRequested':
        case 'close_unity':
          _unityReady = false;
          _backToGamesController.add(decoded);
          unawaited(_closeUnityActivity());
          break;
      }
    } on FormatException catch (error) {
      debugPrint('Ignoring invalid Unity JSON: ${error.message}');
    } catch (error) {
      debugPrint('Could not process Unity message: $error');
    }
  }



  Future<void> _handleEntryPointsRequest(Map<String, dynamic> message) async {
    final matchId = message['matchId'];
    final amount = _positiveInteger(message['amount']);
    if (matchId is! String || matchId.isEmpty || amount == null) {
      debugPrint('Rejecting invalid EntryPointsRequested payload');
      if (matchId is String && matchId.isNotEmpty) {
        await _sendUnityMessage(
            'GameManager',
            'ConfirmGameStartFromFlutter',
            jsonEncode({
              'approved': false,
              'balance': pointsBalance.value ?? 0,
              'matchId': matchId,
            }));
      }
      return;
    }
    var approved = false;
    var balance = pointsBalance.value ?? 0;
    try {
      final result = await _processMatch('start', matchId, amount: amount);
      approved = result['approved'] == true;
      balance = _positiveOrZeroInteger(result['balance']) ?? balance;
      pointsBalance.value = balance;
    } catch (error) {
      debugPrint('Unity match entry was rejected after server error: $error');
      balance = await _readServerBalance() ?? balance;
    }
    await _sendUnityMessage(
        'GameManager',
        'ConfirmGameStartFromFlutter',
        jsonEncode({
          'approved': approved,
          'balance': balance,
          'matchId': matchId,
        }));
  }

  Future<void> _handleMatchResult(
      Map<String, dynamic> message, String action) async {
    final matchId = message['matchId'];
    if (matchId is! String || matchId.isEmpty) {
      debugPrint('Ignoring $action event without a matchId');
      return;
    }
    final idempotencyKey = '${action}_$matchId';
    if (_processedMatchIds.contains(idempotencyKey)) {
      debugPrint('Ignoring duplicate $action event for matchId: $matchId');
      return;
    }
    try {
      Map<String, dynamic>? result;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          result = await _processMatch(action, matchId);
          break;
        } on FirebaseFunctionsException catch (error) {
          const retryableCodes = {
            'unavailable',
            'deadline-exceeded',
            'internal',
            'unknown',
          };
          if (!retryableCodes.contains(error.code) || attempt == 2) rethrow;
          await Future<void>.delayed(
              Duration(milliseconds: 300 * (attempt + 1)));
        }
      }
      if (result == null) return;
      final balance = _positiveOrZeroInteger(result['balance']);
      if (balance == null) return;
      pointsBalance.value = balance;
      _processedMatchIds.add(idempotencyKey);
      while (_processedMatchIds.length > 1000) {
        _processedMatchIds.remove(_processedMatchIds.first);
      }
      if (action == 'win') {
        await _sendUnityMessage(
          'PlayerInfoManager',
          'SetPlayerPointsFromFlutter',
          balance.toString(),
        );
      }
    } catch (error) {
      debugPrint('Could not record Unity match $action: $error');
    }
  }

  Future<void> _handleRefund(Map<String, dynamic> message) async {
    final matchId = message['matchId'];
    final amount = _positiveInteger(message['amount']);
    if (matchId is! String || matchId.isEmpty || amount == null) {
      debugPrint('Ignoring invalid EntryPointsRefundRequested payload');
      return;
    }
    final idempotencyKey = 'refund_$matchId';
    if (_processedMatchIds.contains(idempotencyKey)) {
      debugPrint('Ignoring duplicate refund event for matchId: $matchId');
      return;
    }
    _processedMatchIds.add(idempotencyKey);
    while (_processedMatchIds.length > 1000) {
      _processedMatchIds.remove(_processedMatchIds.first);
    }
    try {
      final result = await _processMatch('refund', matchId, amount: amount);
      final balance = _positiveOrZeroInteger(result['balance']);
      if (balance != null) {
        pointsBalance.value = balance;
        await _sendUnityMessage(
          'PlayerInfoManager',
          'SetPlayerPointsFromFlutter',
          balance.toString(),
        );
      }
    } catch (error) {
      debugPrint('Could not refund Unity match entry: $error');
    }
  }

  Future<Map<String, dynamic>> _processMatch(
    String action,
    String matchId, {
    int? amount,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('processRoyalSnakeMatch');
    final response = await callable.call({
      'action': action,
      'matchId': matchId,
      if (amount != null) 'amount': amount,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<int?> _readServerBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final balance = snapshot.data()?['points'];
      return balance is num ? balance.toInt() : null;
    } catch (_) {
      return null;
    }
  }

  int? _positiveInteger(dynamic value) =>
      value is num && value.isFinite && value > 0 && value == value.toInt()
          ? value.toInt()
          : null;

  int? _positiveOrZeroInteger(dynamic value) =>
      value is num && value.isFinite && value >= 0 && value == value.toInt()
          ? value.toInt()
          : null;

  void registerCallback(
      String action, Function(Map<String, dynamic>) callback) {
    _callbacks[action] = callback;
  }

  void unregisterCallback(String action) => _callbacks.remove(action);

  Stream<Map<String, dynamic>> get onRoomCreated =>
      _roomCreatedController.stream;
  Stream<Map<String, dynamic>> get onRoomJoined => _roomJoinedController.stream;
  Stream<Map<String, dynamic>> get onRoomFailed => _roomFailedController.stream;
  Stream<Map<String, dynamic>> get onGameFinished =>
      _gameFinishedController.stream;
  Stream<Map<String, dynamic>> get onCloseUnity => _closeUnityController.stream;
  Stream<Map<String, dynamic>> get onBackToGamesRequested =>
      _backToGamesController.stream;

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _pointsSubscription?.cancel();
    await _roomCreatedController.close();
    await _roomJoinedController.close();
    await _roomFailedController.close();
    await _gameFinishedController.close();
    await _closeUnityController.close();
    _callbacks.clear();
    _initialized = false;
  }
}
