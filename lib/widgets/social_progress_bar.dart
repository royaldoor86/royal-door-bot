import 'package:flutter/material.dart';
import '../models/social_points_model.dart';
import '../services/social_service.dart';

class SocialProgressBar extends StatelessWidget {
  final String userId;

  const SocialProgressBar({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SocialPointsModel?>(
      stream: SocialService.streamSocialPoints(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final points = snapshot.data;
        if (points == null) {
          return _buildEmptyState(context);
        }

        final currentLevel = points.level;
        final currentStars = points.totalStars;
        
        // حساب التقدم بناءً على 500 نجمة ⭐ لكل مستوى
        const int pointsPerLevel = 500;
        final int levelStartPoints = (currentLevel - 1) * pointsPerLevel;
        final int levelEndPoints = currentLevel * pointsPerLevel;
        
        double progress = (currentStars - levelStartPoints) / pointsPerLevel;
        progress = progress.clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المستوى الاجتماعي الملكي',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                      Text(
                        'المستوى $currentLevel',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  _buildPointsBadge(currentStars),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'النجوم ⭐: $currentStars',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'بقي ${levelEndPoints - currentStars} نجمة ⭐ للمستوى ${currentLevel + 1}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const Divider(height: 25, color: Colors.white10),
              _buildPointsBreakdown(points.pointsByType),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointsBadge(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Colors.amber, size: 16),
          const SizedBox(width: 6),
          Text(
            '$total',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'ابدأ بالتفاعل الاجتماعي لكسب النجوم ⭐ الودية',
          style: TextStyle(color: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildPointsBreakdown(Map<String, int> pointsByType) {
    final types = {
      'follow_given': 'متابعات ممنوحة',
      'follow_received': 'متابعات مستلمة',
      'like_given': 'إعجابات ممنوحة',
      'like_received': 'إعجابات مستلمة',
      'comment_given': 'تعليقات ممنوحة',
      'comment_received': 'تعليقات مستلمة',
      'share_given': 'مشاركات ملفات',
      'share_received': 'تلقي مشاركات',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجل التميز الاجتماعي:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pointsByType.entries.map((entry) {
            final typeName = types[entry.key] ?? entry.key;
            if (entry.value == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$typeName: ${entry.value}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
