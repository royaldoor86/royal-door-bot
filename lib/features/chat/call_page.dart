import 'package:flutter/material.dart';
class CallPage extends StatelessWidget {
  static bool isCallActive = false;
  const CallPage({super.key, required String channelName, required String userId, String? otherUserId, bool isVideoCall = false, String? callId});
  @override
  Widget build(BuildContext context) => const Scaffold();
}
