import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class FacebookFriendSyncService {
  FacebookFriendSyncService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static FacebookFriendSyncPayload parseGraphResponse(
      Map<String, dynamic> data) {
    final friendItems = data['friends'] is Map
        ? (data['friends']['data'] as List<dynamic>?) ?? const []
        : const <dynamic>[];

    final friendProfiles = friendItems
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final pictureData = item['picture'] is Map
              ? item['picture']['data'] as Map<String, dynamic>?
              : null;
          return {
            'facebookId': item['id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Facebook Friend',
            'pictureUrl': pictureData?['url']?.toString() ?? '',
          };
        })
        .where((friend) => (friend['facebookId'] as String).isNotEmpty)
        .toList();

    final friendIds = friendProfiles
        .map((item) => item['facebookId']?.toString())
        .whereType<String>()
        .toList();

    return FacebookFriendSyncPayload(
      facebookId: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      friendIds: friendIds,
      friends: friendProfiles,
    );
  }

  static Future<FacebookFriendSyncPayload?> fetchCurrentUserProfile(
      String accessToken) async {
    final uri = Uri.https('graph.facebook.com', '/v19.0/me', {
      'fields': 'id,name,picture{url},friends{id,name,picture{url}}',
      'access_token': accessToken,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return parseGraphResponse(data);
  }

  static Future<void> syncFacebookFriendsToApp(String accessToken) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final payload = await fetchCurrentUserProfile(accessToken);
    if (payload == null || payload.facebookId.isEmpty) return;

    final syncData = {
      'facebookLinked': true,
      'facebookId': payload.facebookId,
      'facebookProfileName': payload.name,
      'facebookFriendIds': payload.friendIds,
      'facebookFriendsData': payload.friends,
      'facebookLastSyncedAt': FieldValue.serverTimestamp(),
      'authProvider': 'facebook',
      'authProviderDetails': {
        'facebookId': payload.facebookId,
        'facebookProfileName': payload.name,
      },
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(syncData, SetOptions(merge: true));
  }

  static Future<void> clearFacebookSync() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'facebookLinked': false,
      'facebookId': FieldValue.delete(),
      'facebookProfileName': FieldValue.delete(),
      'facebookFriendIds': FieldValue.delete(),
      'facebookFriendsData': FieldValue.delete(),
      'facebookLastSyncedAt': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  static List<Map<String, dynamic>> filterMatchedFacebookUsers({
    required List<Map<String, dynamic>> appUsers,
    required List<String> facebookFriendIds,
  }) {
    final targetIds = facebookFriendIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    return appUsers.where((user) {
      final facebookId = user['facebookId']?.toString();
      return facebookId != null &&
          facebookId.isNotEmpty &&
          targetIds.contains(facebookId);
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getRegisteredFacebookFriendsInApp(
      List<String> facebookFriendIds) async {
    if (facebookFriendIds.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final uniqueIds = facebookFriendIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    for (var i = 0; i < uniqueIds.length; i += 10) {
      final batch = uniqueIds.sublist(
          i, i + 10 > uniqueIds.length ? uniqueIds.length : i + 10);
      final snapshot = await _firestore
          .collection('users')
          .where('facebookId', whereIn: batch)
          .get();
      results.addAll(snapshot.docs
          .map((doc) => {
                'uid': doc.id,
                ...doc.data(),
              })
          .toList());
    }

    return results;
  }
}

class FacebookFriendSyncPayload {
  final String facebookId;
  final String name;
  final List<String> friendIds;
  final List<Map<String, dynamic>> friends;

  const FacebookFriendSyncPayload({
    required this.facebookId,
    required this.name,
    required this.friendIds,
    required this.friends,
  });
}
