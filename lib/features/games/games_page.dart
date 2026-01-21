import 'package:flutter/material.dart';
import '../game_details_page.dart';

class RoyaleMatchPage extends StatelessWidget {
  const RoyaleMatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المباراة الملكية')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('الألعاب المتوفرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 200, // زيادة الارتفاع قليلاً لتجنب الـ Overflow
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final gameTitle = 'لعبة ${index + 1}';
                return _GameCard(
                  title: gameTitle,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailsPage(gameTitle: gameTitle)));
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('اختر لعبة للبدء في المباراة الملكية', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _GameCard({required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8), // إضافة Padding داخلي
          child: Column(
            mainAxisSize: MainAxisSize.min, // جعل العمود يأخذ أقل مساحة ممكنة
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded( // استخدام Expanded للصورة لضمان عدم تجاوز المساحة
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12), 
                    color: Colors.deepPurple.shade50
                  ),
                  child: const Icon(Icons.videogame_asset, size: 40, color: Colors.deepPurple),
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 32),
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('العب الآن', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
