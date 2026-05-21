import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';

class IdChangeRequestDialog extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final String requestId;

  const IdChangeRequestDialog({
    super.key,
    required this.requestData,
    required this.requestId,
  });

  static void show(BuildContext context, Map<String, dynamic> data, String id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => IdChangeRequestDialog(requestData: data, requestId: id),
    );
  }

  @override
  State<IdChangeRequestDialog> createState() => _IdChangeRequestDialogState();
}

class _IdChangeRequestDialogState extends State<IdChangeRequestDialog> {
  bool _isProcessing = false;

  Future<void> _respond(String action) async {
    setState(() => _isProcessing = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('respondToRoyalIdRequest');
      final result = await callable.call({
        'requestId': widget.requestId,
        'action': action,
      });

      if (mounted) {
        if (result.data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(action == 'accept' 
                ? 'تم تحديث المعرف الملكي بنجاح! 👑' 
                : 'تم رفض طلب التغيير'),
              backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
            ),
          );
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newId = widget.requestData['newRoyalId'] ?? '---';

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppTheme.royalGold.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.royalGold.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: AppTheme.royalGold, size: 60),
              const SizedBox(height: 20),
              const HeadingText(
                'هوية ملكية جديدة معروضة! 👑',
                textAlign: TextAlign.center,
                fontSize: 20,
                color: AppTheme.royalGold,
              ),
              const SizedBox(height: 15),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Cairo'),
                  children: [
                    const TextSpan(text: 'يرغب المدير في منحك المعرف المميز التالي:\n\n'),
                    TextSpan(
                      text: '[$newId]',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              if (_isProcessing)
                const CircularProgressIndicator(color: AppTheme.royalGold)
              else
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _respond('reject'),
                        style: TextButton.styleFrom(foregroundColor: Colors.white54),
                        child: const Text('رفض التغيير'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respond('accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.royalGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('موافق، شكراً!', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
