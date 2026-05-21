import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/rewards_service.dart';
import 'dart:ui' as ui;

class RewardsLeaderboardPage extends StatelessWidget {
  const RewardsLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NumberFormat formatter = NumberFormat.decimalPattern('ar');

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F2027),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('لوحة الشرف الملكية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F2027), Color(0xFF203A43)],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
              const SizedBox(height: 10),
              const Text("أفضل 10 جامعي نجوم في المملكة", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 30),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: RewardsService().getLeaderboard(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("لا توجد بيانات حالياً", style: TextStyle(color: Colors.white54)));
                    }

                    final topUsers = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: topUsers.length,
                      itemBuilder: (context, index) {
                        final user = topUsers[index];
                        final isFirst = index == 0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: isFirst ? Colors.amber.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isFirst ? Colors.amber.withValues(alpha: 0.3) : Colors.white10),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isFirst ? Colors.amber : Colors.white24,
                                radius: 20,
                                child: Text("${index + 1}", style: TextStyle(color: isFirst ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text("ID: ${user['royalId']}", style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Orbitron')),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formatter.format(user['stars']), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Orbitron')),
                                  const Text("نجمة", style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
