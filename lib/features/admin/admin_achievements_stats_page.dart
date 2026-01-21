import 'package:flutter/material.dart';
import '../../services/achievements_service.dart';

/// صفحة سجل الإنجازات والإحصائيات الإدارية
class AdminAchievementsStatsPage extends StatelessWidget {
  const AdminAchievementsStatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الإنجازات والإحصائيات'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: AchievementsService().fetchAdminAchievementsStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          final data = snapshot.data ?? {};
          final achievements = data['achievements'] as List<dynamic>? ?? [];
          final stats = data['stats'] as Map<String, dynamic>? ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('إحصائيات عامة:',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...stats.entries.map((e) => ListTile(
                    title: Text(e.key),
                    trailing: Text(e.value.toString()),
                  )),
              const Divider(),
              Text('سجل الإنجازات:',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...achievements.map((a) => Card(
                    child: ListTile(
                      title: Text(a['title'] ?? ''),
                      subtitle: Text(a['description'] ?? ''),
                      trailing: Text('عدد المستخدمين: ${a['usersCount'] ?? 0}'),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
