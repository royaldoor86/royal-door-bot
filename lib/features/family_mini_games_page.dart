import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import '../models/mini_game_model.dart';
import '../app_theme.dart';
import 'dart:ui' as ui;

class FamilyMiniGamesPage extends StatefulWidget {
  final String familyId;
  final String familyName;

  const FamilyMiniGamesPage({
    super.key,
    required this.familyId,
    required this.familyName,
  });

  @override
  State<FamilyMiniGamesPage> createState() => _FamilyMiniGamesPageState();
}

class _FamilyMiniGamesPageState extends State<FamilyMiniGamesPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'ألعاب ${widget.familyName} المصغرة',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.amber),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E), Color(0x00000000)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // زر إنشاء لعبة جديدة
                AppTheme.gradientButton(
                  text: 'إنشاء لعبة جديدة 🎮',
                  onPressed: () => _showCreateGameDialog(),
                ),
                const SizedBox(height: 20),
                // لوحة الصدارة
                _buildLeaderboard(),
                const SizedBox(height: 20),
                // قائمة الألعاب النشطة
                StreamBuilder<List<MiniGameModel>>(
                  stream: _familyService.getFamilyMiniGames(widget.familyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      );
                    }

                    final games = snapshot.data ?? [];
                    if (games.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_esports_outlined,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد ألعاب نشطة حالياً',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'ابدأ لعبة جديدة لتلعب مع أفراد العائلة!',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        return _buildGameCard(games[index]);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('لوحة الصدارة 🏆',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .doc(widget.familyId)
                .collection('game_scores')
                .orderBy('score', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final scores = snapshot.data!.docs;
              if (scores.isEmpty) {
                return const Center(
                  child: Text('لا توجد نتائج بعد',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: scores.length,
                itemBuilder: (context, index) {
                  final score = scores[index].data() as Map<String, dynamic>;
                  return _buildLeaderboardItem(score, index + 1);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> score, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: rank == 1
                  ? Colors.amber.withValues(alpha: 0.3)
                  : (rank == 2
                      ? Colors.grey.withValues(alpha: 0.3)
                      : Colors.brown.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('#$rank',
                  style: TextStyle(
                      color: rank == 1
                          ? Colors.amber
                          : (rank == 2 ? Colors.grey : Colors.brown),
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('users').doc(score['userId']).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('جاري التحميل...',
                      style: TextStyle(color: Colors.white38));
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                return Text(userData?['name'] ?? 'بدون اسم',
                    style: const TextStyle(color: Colors.white));
              },
            ),
          ),
          const SizedBox(width: 10),
          Text('${score['score']} نقطة',
              style: const TextStyle(
                  color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGameCard(MiniGameModel game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getGameIcon(game.type),
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.nameAr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.getTypeNameAr(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (game.isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'نشط',
                      style: TextStyle(color: Colors.green, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              game.description,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white38, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${game.currentPlayers}/${game.maxPlayers}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                if (game.canJoin)
                  ElevatedButton(
                    onPressed: () => _joinGame(game),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'انضمام',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                else if (game.isFull)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'ممتلئ',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.amber),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('مكافأة الفائز: 50 جوهرة 💎',
                        style: TextStyle(color: Colors.amber, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGameIcon(String type) {
    switch (type) {
      case 'quiz':
        return Icons.quiz;
      case 'trivia':
        return Icons.help_outline;
      case 'reaction':
        return Icons.flash_on;
      case 'memory':
        return Icons.psychology;
      default:
        return Icons.sports_esports;
    }
  }

  void _showCreateGameDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'quiz';
    int maxPlayers = 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A050E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.amber, width: 1.5),
          ),
          title: const Text(
            'إنشاء لعبة جديدة',
            style: TextStyle(color: Colors.amber),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم اللعبة',
                    labelStyle: TextStyle(color: Colors.amber),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'وصف اللعبة',
                    labelStyle: TextStyle(color: Colors.amber),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('نوع اللعبة:',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'quiz', child: Text('اختبار')),
                    DropdownMenuItem(
                        value: 'trivia', child: Text('معلومات عامة')),
                    DropdownMenuItem(value: 'reaction', child: Text('رد فعل')),
                    DropdownMenuItem(value: 'memory', child: Text('ذاكرة')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value!),
                  dropdownColor: const Color(0xFF1A050E),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text('الحد الأقصى للاعبين:',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Slider(
                  value: maxPlayers.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  label: '$maxPlayers لاعب',
                  onChanged: (value) =>
                      setDialogState(() => maxPlayers = value.toInt()),
                  activeColor: Colors.amber,
                ),
                Text(
                  '$maxPlayers لاعب',
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('يرجى إدخال اسم اللعبة'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  await _familyService.createMiniGame(
                    familyId: widget.familyId,
                    name: nameController.text.trim(),
                    nameAr: nameController.text.trim(),
                    type: selectedType,
                    description: descController.text.trim(),
                    gameData: {},
                    maxPlayers: maxPlayers,
                    createdBy: user.uid,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إنشاء اللعبة بنجاح! 🎮'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  void _joinGame(MiniGameModel game) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _familyService.joinMiniGame(game.id, user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الانضمام للعبة بنجاح! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
