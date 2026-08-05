import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/user_bootstrap_service.dart';

class UsageStatisticsPage extends StatefulWidget {
  const UsageStatisticsPage({super.key});

  @override
  State<UsageStatisticsPage> createState() => _UsageStatisticsPageState();
}

class _UsageStatisticsPageState extends State<UsageStatisticsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      // تحديث بيانات المستخدم لضمان وجود تاريخ الانضمام
      await UserBootstrapService.bootstrapUser();

      final userDoc = await _db.collection('users').doc(_currentUserId).get();

      // جلب عدد المنشورات والإعجابات والتعليقات
      final postsSnap = await _db
          .collection('posts')
          .where('authorId', isEqualTo: _currentUserId)
          .get();
      int totalLikes = 0;
      int totalComments = 0;
      for (var doc in postsSnap.docs) {
        final data = doc.data();
        totalLikes += (data['likes'] as List?)?.length ?? 0;
        totalComments += (data['commentCount'] as num? ?? 0).toInt();
      }

      // جلب عدد الغرف المملوكة
      final roomsSnap = await _db
          .collection('rooms')
          .where('ownerId', isEqualTo: _currentUserId)
          .get();

      // جلب عدد الأوسمة من المجموعة الفرعية inventory
      final badgesSnap = await _db
          .collection('users')
          .doc(_currentUserId)
          .collection('inventory')
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _statistics = {
            'totalPosts': postsSnap.docs.length,
            'totalLikes': totalLikes,
            'totalComments': totalComments,
            'totalFriends': (data['friends'] as List?)?.length ?? 0,
            'totalFollowers': (data['followers'] as List?)?.length ?? 0,
            'totalFollowing': (data['following'] as List?)?.length ?? 0,
            'totalGiftsReceived': data['totalGiftsReceived'] ?? 0,
            'totalGiftsSent': data['totalGiftsSent'] ?? 0,
            'totalBadges': badgesSnap.docs.length,
            'totalVoiceRooms': roomsSnap.docs.length,
            'joinDate': data['createdAt'] ?? data['joinDate'],
            'lastActive': data['lastActive'] ?? data['lastSeen'],
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'غير متوفر';
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'غير متوفر';
  }

  String _formatDuration(dynamic joinDate) {
    if (joinDate == null) return 'غير متوفر';
    if (joinDate is Timestamp) {
      final joinDateTime = joinDate.toDate();
      final now = DateTime.now();
      final difference = now.difference(joinDateTime);

      if (difference.inDays < 30) {
        return '${difference.inDays} يوم';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()} شهر';
      } else {
        return '${(difference.inDays / 365).floor()} سنة';
      }
    }
    return 'غير متوفر';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'إحصائيات الاستخدام',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.royalGold),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الحساب
                    _buildSectionHeader('معلومات الحساب'),
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      title: 'تاريخ الانضمام',
                      value: _formatDate(_statistics['joinDate']),
                    ),
                    _buildInfoCard(
                      icon: Icons.access_time,
                      title: 'مدة العضوية',
                      value: _formatDuration(_statistics['joinDate']),
                    ),
                    const SizedBox(height: 30),

                    // إحصائيات النشاط
                    _buildSectionHeader('إحصائيات النشاط'),
                    _buildStatCard(
                      icon: Icons.article,
                      title: 'إجمالي المنشورات',
                      value: _statistics['totalPosts'].toString(),
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      icon: Icons.favorite,
                      title: 'إجمالي الإعجابات',
                      value: _statistics['totalLikes'].toString(),
                      color: Colors.red,
                    ),
                    _buildStatCard(
                      icon: Icons.comment,
                      title: 'إجمالي التعليقات',
                      value: _statistics['totalComments'].toString(),
                      color: Colors.green,
                    ),
                    const SizedBox(height: 30),

                    // إحصائيات العلاقات
                    _buildSectionHeader('إحصائيات العلاقات'),
                    _buildStatCard(
                      icon: Icons.people,
                      title: 'إجمالي الأصدقاء',
                      value: _statistics['totalFriends'].toString(),
                      color: Colors.purple,
                    ),
                    _buildStatCard(
                      icon: Icons.person_add,
                      title: 'إجمالي المتابعين',
                      value: _statistics['totalFollowers'].toString(),
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      icon: Icons.person_add_alt,
                      title: 'إجمالي المتابع',
                      value: _statistics['totalFollowing'].toString(),
                      color: Colors.cyan,
                    ),
                    const SizedBox(height: 30),

                    // إحصائيات المكافآت
                    _buildSectionHeader('إحصائيات المكافآت'),
                    _buildStatCard(
                      icon: Icons.card_giftcard,
                      title: 'الهدايا المستلمة',
                      value: _statistics['totalGiftsReceived'].toString(),
                      color: AppTheme.royalGold,
                    ),
                    _buildStatCard(
                      icon: Icons.card_giftcard,
                      title: 'الهدايا المرسلة',
                      value: _statistics['totalGiftsSent'].toString(),
                      color: Colors.pink,
                    ),
                    _buildStatCard(
                      icon: Icons.workspace_premium,
                      title: 'الأوسمة',
                      value: _statistics['totalBadges'].toString(),
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 30),

                    // إحصائيات الغرف الصوتية
                    _buildSectionHeader('إحصائيات الغرف الصوتية'),
                    _buildStatCard(
                      icon: Icons.mic,
                      title: 'الغرف الصوتية',
                      value: _statistics['totalVoiceRooms'].toString(),
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 30),

                    // معلومات إضافية
                    _buildInfoCard(
                      icon: Icons.info_outline,
                      title: 'ملاحظة',
                      value: 'يتم تحديث هذه الإحصائيات تلقائياً',
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.royalGold,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.royalGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.royalGold, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
