import 'package:flutter/material.dart';
class IncomingCallOverlay extends StatelessWidget {
  const IncomingCallOverlay({super.key, required this.callData, required this.callId, required this.onAccept, required this.onDecline});
  final dynamic callData;
  final String callId;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
