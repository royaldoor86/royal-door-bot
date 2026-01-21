import 'package:flutter/material.dart';

class GameDetailsPage extends StatelessWidget {
  final String gameTitle;
  const GameDetailsPage({super.key, required this.gameTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل $gameTitle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.deepPurple.shade50,
                ),
                child: const Icon(Icons.videogame_asset, size: 64, color: Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              gameTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'وصف اللعبة: هذه لعبة ملكية ممتعة يمكنك فيها التنافس مع لاعبين آخرين للفوز بالجوائز. يمكنك اللعب منفردًا أو مع أصدقائك، وتتوفر غرف خاصة وعامة.',
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.people, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('عدد اللاعبين: 2-8'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 8),
                Text('جوائز للفائزين'),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: فتح صفحة إنشاء غرفة
              },
              icon: const Icon(Icons.add_box_rounded),
              label: const Text('إنشاء غرفة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'الغرف المتاحة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(
                    Icons.meeting_room,
                    color: Colors.deepPurple,
                  ),
                  title: Text('غرفة ${index + 1}'),
                  subtitle: const Text('عدد اللاعبين: 4/8'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: الانضمام للغرفة
                    },
                    child: const Text('انضمام'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                    ),
                  ),
                  onTap: () {
                    // TODO: فتح تفاصيل الغرفة
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
