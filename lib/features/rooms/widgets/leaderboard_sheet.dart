
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app_theme.dart';

class LeaderboardSheet extends StatefulWidget {
  final String roomId;

  const LeaderboardSheet({super.key, required this.roomId});

  @override
  State<LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<LeaderboardSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['يومي', 'اسبوعي', 'شهري'];
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchLeaderboardData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging || _currentTabIndex == _tabController.index) return;
    setState(() {
      _currentTabIndex = _tabController.index;
    });
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    DateTime startDate;
    final now = DateTime.now();
    switch (_tabController.index) {
      case 0: // Daily
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 1: // Weekly
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 2: // Monthly
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    try {
      final giftsSnap = await FirebaseFirestore.instance
          .collection('sent_gifts')
          .where('roomId', isEqualTo: widget.roomId)
          .where('sentAt', isGreaterThanOrEqualTo: startDate)
          .get();

      Map<String, Map<String, dynamic>> supporters = {};
      for (var doc in giftsSnap.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String;
        final totalCost = (data['totalCost'] ?? 0) as int;

        if (supporters.containsKey(senderId)) {
          supporters[senderId]!['totalCost'] =
              (supporters[senderId]!['totalCost'] ?? 0) + totalCost;
        } else {
          supporters[senderId] = {
            'senderId': senderId,
            'senderName': data['senderName'] ?? 'مستخدم',
            'totalCost': totalCost,
            'senderPhotoUrl': data['senderPhotoUrl'],
          };
        }
      }

      List<Future> photoFetchFutures = [];
      for (var supporter in supporters.values) {
        if (supporter['senderPhotoUrl'] == null ||
            (supporter['senderPhotoUrl'] as String).isEmpty) {
          photoFetchFutures.add(FirebaseFirestore.instance
              .collection('users')
              .doc(supporter['senderId'])
              .get()
              .then((userDoc) {
            if (userDoc.exists) {
              supporter['senderPhotoUrl'] = userDoc.data()?['profilePic'];
            }
          }));
        }
      }
      if (photoFetchFutures.isNotEmpty) {
        await Future.wait(photoFetchFutures);
      }

      var sortedSupporters = supporters.values.toList();
      sortedSupporters
          .sort((a, b) => (b['totalCost'] as int).compareTo(a['totalCost'] as int));

      if (mounted) {
        setState(() {
          _leaderboardData = sortedSupporters;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ في جلب قائمة المتصدرين')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 10),
            width: 45,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(10)),
          ),
          const Text('👑 متصدرو الدعم 👑',
              style: TextStyle(
                  color: AppTheme.royalGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: _tabs.map((String title) => Tab(text: title)).toList(),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Almarai'),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppTheme.royalGold,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((_) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
                }
                if (_leaderboardData.isEmpty) {
                  return const Center(child: Text('لا يوجد داعمون في هذه الفترة', style: TextStyle(color: Colors.white38, fontFamily: 'Almarai')));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _leaderboardData.length,
                  itemBuilder: (context, index) {
                    return _buildSupporterCard(index, _leaderboardData[index]);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupporterCard(int index, Map<String, dynamic> supporterData) {
    final rank = index + 1;
    final name = supporterData['senderName'] as String;
    final totalCost = supporterData['totalCost'] as int;
    final photoUrl = supporterData['senderPhotoUrl'] as String?;

    Color borderColor = Colors.transparent;
    Color iconColor = Colors.grey;
    IconData rankIcon = Icons.shield;

    if (rank == 1) {
      borderColor = Colors.amber.withValues(alpha: 0.5);
      iconColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      borderColor = Colors.grey.withValues(alpha: 0.5);
      iconColor = Colors.grey[300]!;
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      borderColor = const Color(0xFFCD7F32).withValues(alpha: 0.5);
      iconColor = const Color(0xFFCD7F32);
      rankIcon = Icons.emoji_events;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank <= 3 ? iconColor.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: TextStyle(
              color: rank <=3 ? iconColor : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              if (rank <= 3) Icon(rankIcon, color: iconColor, size: 50),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white10,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white38)
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Almarai',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$totalCost',
                style: const TextStyle(
                    color: AppTheme.royalGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.diamond_outlined, color: Colors.cyanAccent, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
