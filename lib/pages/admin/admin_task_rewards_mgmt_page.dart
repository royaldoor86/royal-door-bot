import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';

class AdminTaskRewardsMgmtPage extends StatefulWidget {
  const AdminTaskRewardsMgmtPage({super.key});

  @override
  State<AdminTaskRewardsMgmtPage> createState() =>
      _AdminTaskRewardsMgmtPageState();
}

class _AdminTaskRewardsMgmtPageState extends State<AdminTaskRewardsMgmtPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'إدارة المقالات 📄'),
              Tab(text: 'إعدادات القيم ⚙️'),
            ],
            labelColor: DesignTokens.primaryGold,
            unselectedLabelColor: Colors.white54,
            indicatorColor: DesignTokens.primaryGold,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildArticlesManagement(),
                _buildRewardSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesManagement() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: RoyalButton(
            label: 'إضافة مقال جديد ➕',
            onPressed: () => _showArticleDialog(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('royal_articles')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: BodyText('لا توجد مقالات حالياً'));
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return RoyalCard(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Image.network(data['image'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image)),
                      title: BodyText(data['title'] ?? '',
                          fontWeight: FontWeight.bold),
                      subtitle: CaptionText(data['content'] ?? '', maxLines: 1),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showArticleDialog(doc: doc)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteArticle(doc.id)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardSettings() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('admin_settings').doc('task_rewards').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ??
            {
              'article_read_reward': 50,
              'daily_checkin_base': 50,
              'daily_checkin_bonus': 150,
              'watch_reward_15m': 735,
              'stay_reward_per_15m': 100,
              'ad_video_reward': 100,
            };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSettingTile('مكافأة قراءة المقال (30 ثانية)',
                  'article_read_reward', data['article_read_reward']),
              _buildSettingTile('مكافأة الدخول اليومي (أساسي)',
                  'daily_checkin_base', data['daily_checkin_base']),
              _buildSettingTile('مكافأة الدخول اليومي (يوم 5+)',
                  'daily_checkin_bonus', data['daily_checkin_bonus']),
              _buildSettingTile('مكافأة إكمال 15 دقيقة مشاهدة',
                  'watch_reward_15m', data['watch_reward_15m']),
              _buildSettingTile('مكافأة البقاء في التطبيق (لكل 15 دقيقة)',
                  'stay_reward_per_15m', data['stay_reward_per_15m']),
              _buildSettingTile('مكافأة مشاهدة إعلان فيديو', 'ad_video_reward',
                  data['ad_video_reward']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingTile(String label, String key, dynamic value) {
    final controller = TextEditingController(text: value.toString());
    return RoyalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(child: BodyText(label)),
            SizedBox(
              width: 80,
              child: RoyalTextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.save, color: DesignTokens.primaryGold),
              onPressed: () =>
                  _updateSetting(key, int.tryParse(controller.text) ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSetting(String key, int value) async {
    await _db.collection('admin_settings').doc('task_rewards').set({
      key: value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      AppTheme.showSuccessSnackbar(context, 'تم تحديث القيمة بنجاح ✅');
    }
  }

  void _showArticleDialog({DocumentSnapshot? doc}) {
    final data = doc?.data() as Map<String, dynamic>?;
    final titleController = TextEditingController(text: data?['title'] ?? '');
    final contentController =
        TextEditingController(text: data?['content'] ?? '');
    final imageController = TextEditingController(text: data?['image'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: DesignTokens.backgroundDarkDeep,
          title: HeadingText(doc == null ? 'إضافة مقال جديد' : 'تعديل المقال'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoyalTextField(
                    controller: titleController, hintText: 'العنوان'),
                const SizedBox(height: 10),
                RoyalTextField(
                    controller: contentController,
                    hintText: 'المحتوى',
                    maxLines: 5),
                const SizedBox(height: 10),
                RoyalTextField(
                    controller: imageController, hintText: 'رابط الصورة'),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            RoyalButton(
              label: 'حفظ',
              width: 100,
              onPressed: () async {
                final articleData = {
                  'title': titleController.text,
                  'content': contentController.text,
                  'image': imageController.text,
                  'createdAt':
                      data?['createdAt'] ?? FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (doc == null) {
                  await _db.collection('royal_articles').add(articleData);
                } else {
                  await doc.reference.update(articleData);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteArticle(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المقال'),
        content: const Text('هل أنت متأكد من حذف هذا المقال؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('royal_articles').doc(id).delete();
    }
  }
}
