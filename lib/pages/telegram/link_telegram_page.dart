import 'package:flutter/material.dart';
import '../../services/telegram_link_service.dart';

class LinkTelegramPage extends StatefulWidget {
  const LinkTelegramPage({Key? key}) : super(key: key);

  @override
  State<LinkTelegramPage> createState() => _LinkTelegramPageState();
}

class _LinkTelegramPageState extends State<LinkTelegramPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  String? _message;
  Color _messageColor = Colors.red;

  Future<void> _linkTelegram() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _message = "⚠️ الرجاء إدخال كود الربط";
        _messageColor = Colors.orange;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    final result = await TelegramLinkService.linkTelegram(code);

    setState(() {
      _loading = false;
      _message = result;
      _messageColor = result.contains("تم") ? Colors.green : Colors.red;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔗 ربط تلغرام"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "اربط حسابك في Telegram مع التطبيق 👑",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "انسخ كود الربط من بوت تلغرام ثم أدخله هنا.\n"
              "⏳ الكود صالح لمدة 5 دقائق فقط.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: "كود الربط",
                hintText: "مثال: NNLVRT",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _linkTelegram,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "🔗 ربط الحساب",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 20),
              Text(
                _message!,
                style: TextStyle(
                  color: _messageColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
