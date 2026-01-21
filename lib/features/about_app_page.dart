import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حول التطبيق'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.info_outline, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Global Social App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            const Text(
              'الإصدار 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text(
              'تطبيق غرف صوتية وألعاب جماعية واستثمار وهدايا مصمم ليجمع الاصدقاء في جو ترفيهي ممتع ، مع نظام رومات وبروفايل متطور ، وهدايا وتأثيرات جميله داخل الغرف .',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            _buildInfoTile('المطور', 'فريق Royal Door'),
            _buildInfoTile('سنة الإصدار', '2024'),
            _buildInfoTile('الموقع الرسمي', 'www.royaldoor.com'),
            const SizedBox(height: 40),
            const Text(
              '© 2024 Royal Door Team. جميع الحقوق محفوظة.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
