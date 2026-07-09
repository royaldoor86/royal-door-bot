import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomNotificationsSheet extends StatefulWidget {
  final String roomId;
  const CustomNotificationsSheet({super.key, required this.roomId});

  @override
  State<CustomNotificationsSheet> createState() =>
      _CustomNotificationsSheetState();
}

class _CustomNotificationsSheetState extends State<CustomNotificationsSheet> {
  final TextEditingController _messageController = TextEditingController();
  bool _enableNotifications = true;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 45,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          const Text(
            'إشعارات مخصصة 🔔',
            style: TextStyle(
                color: Colors.teal, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'تفعيل الإشعارات',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Switch(
                              value: _enableNotifications,
                              onChanged: (v) {
                                setState(() => _enableNotifications = v);
                              },
                              activeThumbColor: Colors.teal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'رسالة ترحيب مخصصة',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _messageController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'أدخل رسالة الترحيب...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _saveSettings,
                            child: const Text(
                              'حفظ الإعدادات',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إشعارات سريعة',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        _quickNotification('🎉 معركة جديدة!', 'بدء معركة'),
                        _quickNotification('🎁 هدية جديدة!', 'إرسال هدية'),
                        _quickNotification('👋 ترحيب', 'دخول مستخدم'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _quickNotification(String title, String subtitle) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.teal),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38)),
        trailing: Switch(
          value: true,
          onChanged: (v) {},
          activeThumbColor: Colors.teal,
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .update({
      'customNotifications': {
        'enabled': _enableNotifications,
        'welcomeMessage': _messageController.text.trim(),
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ إعدادات الإشعارات ✅'),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.pop(context);
    }
  }
}
