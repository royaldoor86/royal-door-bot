import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminTelegramStatsPage extends StatefulWidget {
  const AdminTelegramStatsPage({super.key});

  @override
  State<AdminTelegramStatsPage> createState() => _AdminTelegramStatsPageState();
}

class _AdminTelegramStatsPageState extends State<AdminTelegramStatsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _totalUsers = 0;
  int _activeToday = 0;
  bool _loading = true;
  String _searchQuery = '';
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final snapshot = await _db.collection('telegram_users').get();
      // Use UTC to match Firebase Cloud Function
      final today = DateTime.now().toUtc().toIso8601String().split('T')[0];
      final todayActivity =
          await _db.collection('telegram_daily_activity').doc(today).get();

      setState(() {
        _totalUsers = snapshot.docs.length;
        _activeToday = todayActivity.exists
            ? (todayActivity.data()?['activeUsers'] as List?)?.length ?? 0
            : 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _loading = true;
    });
    await _loadStats();
  }

  Future<void> _openTelegramProfile(String username) async {
    final url = 'https://t.me/$username';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B25),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A3A),
        title: const Text(
          'إحصائيات بوت التلغرام',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.amber,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 16,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                    child: Column(
                      children: [
                        // بطاقة الإحصائيات العامة
                        _buildStatsCard(),
                        SizedBox(height: isSmallScreen ? 12 : 20),
                        // قسم المستخدمين النشطين اليوم
                        _buildActiveTodaySection(),
                        SizedBox(height: isSmallScreen ? 12 : 20),
                        // شريط البحث والفلترة
                        _buildSearchAndFilterBar(),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        // قائمة المستخدمين
                        SizedBox(
                          height: constraints.maxHeight -
                              (isSmallScreen
                                  ? 280
                                  : 350), // Adjust based on other elements
                          child: _buildUsersList(),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E3A5F),
                Color(0xFF0F1B25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3), width: 1),
          ),
          child: isSmallScreen
              ? Column(
                  children: [
                    _buildStatItem('$_totalUsers', 'إجمالي المشتركين',
                        Colors.amber, isSmallScreen),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 16),
                    _buildStatItem('$_activeToday', 'نشطون اليوم',
                        Colors.lightBlueAccent, isSmallScreen),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _loading
                        ? const CircularProgressIndicator(color: Colors.amber)
                        : _buildStatItem('$_totalUsers', 'إجمالي المشتركين',
                            Colors.amber, isSmallScreen),
                    Container(
                      height: 60,
                      width: 1,
                      color: Colors.white24,
                    ),
                    _loading
                        ? const CircularProgressIndicator(color: Colors.amber)
                        : _buildStatItem('$_activeToday', 'نشطون اليوم',
                            Colors.lightBlueAccent, isSmallScreen),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String value, String label, Color color, bool isSmallScreen) {
    if (_loading) {
      return const CircularProgressIndicator(color: Colors.amber);
    }
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 32 : 36,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTodaySection() {
    // Use UTC to match Firebase Cloud Function
    final today = DateTime.now().toUtc().toIso8601String().split('T')[0];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A3A),
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                    topRight: Radius.circular(isSmallScreen ? 16 : 20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.today, color: Colors.lightBlueAccent),
                    const SizedBox(width: 12),
                    const Text(
                      'المستخدمون النشطون اليوم',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_activeToday نشط',
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: isSmallScreen ? 120 : 150,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _db
                      .collection('telegram_daily_activity')
                      .doc(today)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.lightBlueAccent),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: isSmallScreen ? 40 : 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'لا يوجد نشاط اليوم',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final activeUsers =
                        data['activeUsers'] as List<dynamic>? ?? [];

                    if (activeUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: isSmallScreen ? 40 : 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'لا يوجد نشاط اليوم',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: activeUsers.length,
                      itemBuilder: (context, index) {
                        final userId = activeUsers[index].toString();
                        return _buildActiveUserTile(userId, isSmallScreen);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _normalizeUserData(
      Map<String, dynamic> rawUser, String fallbackId) {
    return {
      'telegramId':
          rawUser['telegramId'] ?? rawUser['telegram_id'] ?? fallbackId,
      'firstName': (rawUser['firstName'] ??
              rawUser['first_name'] ??
              rawUser['name'] ??
              '')
          .toString(),
      'lastName':
          (rawUser['lastName'] ?? rawUser['last_name'] ?? '').toString(),
      'username': (rawUser['username'] ?? rawUser['userName'] ?? '').toString(),
      'joinedAt': rawUser['joinedAt'] ?? rawUser['joined_at'],
      'languageCode':
          (rawUser['languageCode'] ?? rawUser['language_code'] ?? 'ar')
              .toString(),
      'verifiedPhone': (rawUser['verified_phone'] ?? rawUser['phoneNumber'] ?? '').toString(),
    };
  }

  Widget _buildActiveUserTile(String userId, bool isSmallScreen) {
    return FutureBuilder<DocumentSnapshot>(
      future: _db.collection('telegram_users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final user = snapshot.data!.data() as Map<String, dynamic>;
        final normalizedUser = _normalizeUserData(user, userId);
        final username = normalizedUser['username'].toString().isEmpty
            ? 'غير معروف'
            : normalizedUser['username'].toString();
        final firstName = normalizedUser['firstName'].toString();
        final verifiedPhone = normalizedUser['verifiedPhone'].toString();

        return Container(
          margin: EdgeInsets.symmetric(
              vertical: 2, horizontal: isSmallScreen ? 4 : 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: isSmallScreen ? 14 : 16,
              backgroundColor: Colors.lightBlueAccent.withValues(alpha: 0.2),
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    firstName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 11 : 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (verifiedPhone.isNotEmpty)
                  const Icon(Icons.verified_user, color: Colors.green, size: 10),
              ],
            ),
            subtitle: Row(
              children: [
                Text(
                  '@$username',
                  style: TextStyle(
                    color: Colors.lightBlueAccent.withValues(alpha: 0.8),
                    fontSize: isSmallScreen ? 9 : 11,
                  ),
                ),
                if (verifiedPhone.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    verifiedPhone,
                    style: TextStyle(
                      color: Colors.greenAccent.withValues(alpha: 0.6),
                      fontSize: isSmallScreen ? 8 : 10,
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.open_in_new,
                color: Colors.lightBlueAccent,
                size: isSmallScreen ? 14 : 16,
              ),
              onPressed: () => _openTelegramProfile(username),
              tooltip: 'فتح في تيليجرام',
            ),
            onTap: () => _openTelegramProfile(username),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilterBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 10 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A3A),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'بحث عن مستخدم...',
                    hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: isSmallScreen ? 12 : 14),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.white54, size: isSmallScreen ? 20 : 24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                  ),
                  style: TextStyle(
                      color: Colors.white, fontSize: isSmallScreen ? 12 : 14),
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              IconButton(
                icon: Icon(
                  _showActiveOnly ? Icons.filter_list_alt : Icons.filter_list,
                  color:
                      _showActiveOnly ? Colors.lightBlueAccent : Colors.white54,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: () {
                  setState(() {
                    _showActiveOnly = !_showActiveOnly;
                  });
                },
                tooltip: 'فلترة النشطين',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A3A),
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                    topRight: Radius.circular(isSmallScreen ? 16 : 20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.amber),
                    const SizedBox(width: 12),
                    const Text(
                      'قائمة المشتركين',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_totalUsers مستخدم',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('telegram_users')
                      .orderBy('joined_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: isSmallScreen ? 48 : 64,
                              color: Colors.white24,
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            const Text(
                              'لا يوجد مشتركين بعد',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final users = snapshot.data!.docs;

                    // Filter users based on search query and active filter
                    List<QueryDocumentSnapshot> filteredUsers = users;

                    if (_searchQuery.isNotEmpty) {
                      filteredUsers = filteredUsers.where((doc) {
                        final user = doc.data() as Map<String, dynamic>;
                        final normalizedUser = _normalizeUserData(user, doc.id);
                        final username =
                            normalizedUser['username'].toString().toLowerCase();
                        final firstName = normalizedUser['firstName']
                            .toString()
                            .toLowerCase();
                        final lastName =
                            normalizedUser['lastName'].toString().toLowerCase();
                        return username.contains(_searchQuery) ||
                            firstName.contains(_searchQuery) ||
                            lastName.contains(_searchQuery);
                      }).toList();
                    }

                    // Note: Active filter is disabled for now due to async complexity
                    // To enable, we need to fetch active users separately first

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: isSmallScreen ? 48 : 64,
                              color: Colors.white24,
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            const Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user =
                            filteredUsers[index].data() as Map<String, dynamic>;
                        return _buildUserTile(user, isSmallScreen);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, bool isSmallScreen) {
    final normalizedUser = _normalizeUserData(user, '');
    final username = normalizedUser['username'].toString().isEmpty
        ? 'غير معروف'
        : normalizedUser['username'].toString();
    final firstName = normalizedUser['firstName'].toString();
    final lastName = normalizedUser['lastName'].toString();
    final joinedAtValue = normalizedUser['joinedAt'];
    final joinedAt = joinedAtValue is Timestamp ? joinedAtValue : null;
    final languageCode = normalizedUser['languageCode'].toString();
    final verifiedPhone = normalizedUser['verifiedPhone'].toString();

    String displayName = firstName;
    if (lastName.isNotEmpty) {
      displayName += ' $lastName';
    }
    if (displayName.isEmpty) {
      displayName = username;
    }

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 2 : 4,
        horizontal: isSmallScreen ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B25),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 4 : 8,
        ),
        leading: CircleAvatar(
          radius: isSmallScreen ? 18 : 20,
          backgroundColor: Colors.amber.withValues(alpha: 0.2),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 13 : 15,
                ),
              ),
            ),
            if (verifiedPhone.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, color: Colors.green, size: 10),
                    SizedBox(width: 2),
                    Text(
                      'موثق',
                      style: TextStyle(color: Colors.green, fontSize: 8),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '@$username',
                  style: TextStyle(
                    color: Colors.amber.withValues(alpha: 0.8),
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
                if (verifiedPhone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    verifiedPhone,
                    style: TextStyle(
                      color: Colors.greenAccent.withValues(alpha: 0.8),
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Row(
              children: [
                Icon(
                  Icons.language,
                  size: isSmallScreen ? 10 : 12,
                  color: Colors.white54,
                ),
                SizedBox(width: isSmallScreen ? 2 : 4),
                Text(
                  languageCode.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: isSmallScreen ? 9 : 11,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 12),
                Icon(
                  Icons.access_time,
                  size: isSmallScreen ? 10 : 12,
                  color: Colors.white54,
                ),
                SizedBox(width: isSmallScreen ? 2 : 4),
                Text(
                  joinedAt != null
                      ? _formatDate(joinedAt.toDate())
                      : 'غير معروف',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: isSmallScreen ? 9 : 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.open_in_new,
            color: Colors.amber,
            size: isSmallScreen ? 18 : 24,
          ),
          onPressed: () => _openTelegramProfile(username),
          tooltip: 'فتح في تيليجرام',
        ),
        onTap: () => _openTelegramProfile(username),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
