import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class InvestmentPage extends StatefulWidget {
  const InvestmentPage({super.key});

  @override
  State<InvestmentPage> createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _countdownTimer;

  Color _currentBgColor = const Color(0xFF3E2723);
  Color _currentGradientEnd = const Color(0xFF1B0000);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _currentBgColor = const Color(0xFF3E2723);
              _currentGradientEnd = const Color(0xFF1B0000);
              break;
            case 1:
              _currentBgColor = const Color(0xFF0D1B3E);
              _currentGradientEnd = const Color(0xFF020A1A);
              break;
            case 2:
              _currentBgColor = const Color(0xFF0B2D16);
              _currentGradientEnd = const Color(0xFF05150B);
              break;
          }
        });
      }
    });

    // تحديث الواجهة كل ثانية للعدادات
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // حساب الوقت المتبقي كنص
  String _getRemainingTime(Timestamp endTime) {
    final now = DateTime.now();
    final end = endTime.toDate();
    final difference = end.difference(now);

    if (difference.isNegative) return "مكتملة ✅";

    if (difference.inDays > 0) {
      return "${difference.inDays} يوم و ${difference.inHours % 24} ساعة";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} ساعة و ${difference.inMinutes % 60} دقيقة";
    } else {
      return "${difference.inMinutes % 60} دقيقة و ${difference.inSeconds % 60} ثانية";
    }
  }

  Future<void> _handleStartInvestment(Map<String, dynamic> plan, String type, UserModel userData, double currentUsdBalance) async {
    dynamic balance = 0;
    String fieldToUpdate = '';
    
    if (type == 'gems') {
      balance = userData.gems;
      fieldToUpdate = 'gems';
    } else if (type == 'coins') {
      balance = userData.coins;
      fieldToUpdate = 'coins';
    } else {
      balance = currentUsdBalance;
      fieldToUpdate = 'balance_usd';
    }

    int cost = plan['costValue'];
    if (balance < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، رصيدك غير كافٍ لإتمام هذه الصفقة ❌')));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _currentBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد العملية الملكية', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        content: Text('هل تريد استثمار $cost ${type == 'financial' ? '\$' : (type == 'gems' ? 'جوهرة' : 'كوينز')} في (${plan['title']})؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('بدء الصفقة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.runTransaction((tx) async {
          final userRef = _db.collection('users').doc(userData.uid);
          tx.update(userRef, {fieldToUpdate: balance - cost});
          
          final investRef = userRef.collection('investments').doc();
          tx.set(investRef, {
            'title': plan['title'],
            'amount': cost,
            'profitRate': plan['profit'],
            'type': type,
            'startTime': FieldValue.serverTimestamp(),
            'endTime': Timestamp.fromDate(DateTime.now().add(Duration(days: plan['days']))),
            'status': 'active',
            'isFinancial': type == 'financial',
          });
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم توقيع الصفقة بنجاح! الرصيد محدث 👑'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ فني، حاول مرة أخرى')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<DocumentSnapshot>(
        stream: user != null ? _db.collection('users').doc(user.uid).snapshots() : null,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Scaffold(backgroundColor: Color(0xFF15050B), body: Center(child: CircularProgressIndicator(color: Colors.amber)));
          
          final userDataMap = userSnapshot.data!.data() as Map<String, dynamic>;
          final userData = UserModel.fromMap(userDataMap, userSnapshot.data!.id);
          final double currentUsdBalance = (userDataMap['balance_usd'] ?? 0).toDouble();

          return Scaffold(
            backgroundColor: const Color(0xFF15050B),
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [_currentBgColor, _currentGradientEnd],
                ),
              ),
              child: NestedScrollView(
                physics: const BouncingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0, pinned: true, floating: true,
                      leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      title: const Text('الاستثمار الملكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      actions: [IconButton(icon: const Icon(Icons.help_outline, color: Colors.amber), onPressed: () {})],
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildStatusCard(userData, currentUsdBalance),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Align(alignment: Alignment.centerRight, child: Text('خطط الاستثمار المتاحة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                          ),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: Colors.amber,
                          labelColor: Colors.amber,
                          unselectedLabelColor: Colors.white38,
                          tabs: const [
                            Tab(text: 'الكوينز'),
                            Tab(text: 'الجواهر'),
                            Tab(text: 'الاستثمار المالي \$'),
                          ],
                        ),
                        bgColor: _currentBgColor,
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(userData, currentUsdBalance, 'coins'),
                    _buildTabContent(userData, currentUsdBalance, 'gems'),
                    _buildTabContent(userData, currentUsdBalance, 'financial'),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildTabContent(UserModel userData, double usdBalance, String type) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          type == 'coins' ? _buildCoinsPlans(userData, usdBalance) : 
          type == 'gems' ? _buildGemsPlans(userData, usdBalance) : 
          _buildFinancialPlans(userData, usdBalance),
          
          const Padding(
            padding: EdgeInsets.all(20),
            child: Divider(color: Colors.white10),
          ),
          const Text('عقودك الاستثمارية النشطة', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          _buildActiveInvestmentsSection(userData, type),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildActiveInvestmentsSection(UserModel userData, String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(userData.uid).collection('investments').where('type', isEqualTo: type).where('status', isEqualTo: 'active').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('لا توجد عقود نشطة حالياً', style: TextStyle(color: Colors.white24, fontSize: 12)));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final inv = docs[index].data() as Map<String, dynamic>;
            final endTime = (inv['endTime'] as Timestamp);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: Colors.amber, size: 20),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inv['title'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('الموعد النهائي: ${_getRemainingTime(endTime)}', style: TextStyle(color: _getRemainingTime(endTime).contains('✅') ? Colors.greenAccent : Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  if (_getRemainingTime(endTime).contains('✅'))
                    ElevatedButton(
                      onPressed: () {}, // هنا نضع كود الاستلام لاحقاً
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(60, 30)),
                      child: const Text('استلام', style: TextStyle(fontSize: 10)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusCard(UserModel userData, double usdBalance) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(userData.uid).collection('investments').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, invSnap) {
        int activeCount = invSnap.hasData ? invSnap.data!.docs.length : 0;
        String balanceText = _tabController.index == 0 ? userData.coins.toString() : (_tabController.index == 1 ? userData.gems.toString() : usdBalance.toStringAsFixed(2));
        IconData balanceIcon = _tabController.index == 0 ? Icons.stars : (_tabController.index == 1 ? Icons.diamond : Icons.attach_money);
        Color iconColor = _tabController.index == 0 ? Colors.amber : (_tabController.index == 1 ? Colors.blue : Colors.green);

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Column(
            children: [
              const Text('رصيد الاستثمار المتاح', style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(balanceIcon, color: iconColor, size: 40),
                  const SizedBox(width: 15),
                  Text(balanceText, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: _buildMiniStat('الأرباح المتوقعة', activeCount > 0 ? 'قيد النمو' : '0')),
                  Container(width: 1, height: 40, color: Colors.white10),
                  Expanded(child: _buildMiniStat('العمليات النشطة', activeCount.toString())),
                ],
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]);
  }

  Widget _buildGemsPlans(UserModel userData, double usd) {
    final plans = [
      {'title': 'خطة الزمرد', 'profit': 'ربح 15% شهرياً', 'cost': '5k جوهرة', 'costValue': 5000, 'days': 30, 'icon': Icons.trending_up, 'iconColor': Colors.greenAccent},
      {'title': 'خطة الياقوت', 'profit': 'ربح 54% كل 3 أشهر', 'cost': '25k جوهرة', 'costValue': 25000, 'days': 90, 'icon': Icons.trending_down, 'iconColor': Colors.redAccent},
      {'title': 'خطة الماس', 'profit': 'ربح 120% سنوياً', 'cost': '50k جوهرة', 'costValue': 50000, 'days': 365, 'icon': Icons.diamond, 'iconColor': Colors.cyanAccent},
    ];
    return _buildPlanList(plans, 'gems', userData, usd);
  }

  Widget _buildCoinsPlans(UserModel userData, double usd) {
    final plans = [
      {'title': 'خطة الذهب العالمي', 'profit': 'ربح 12% شهرياً', 'cost': '100k كوينز', 'costValue': 100000, 'days': 30, 'icon': Icons.trending_up, 'iconColor': Colors.amber},
      {'title': 'خطة الياقوت', 'profit': 'ربح 54% كل 3 أشهر', 'cost': '250k كوينز', 'costValue': 250000, 'days': 90, 'icon': Icons.trending_down, 'iconColor': Colors.redAccent},
      {'title': 'خطة الماس', 'profit': 'ربح 120% سنوياً', 'cost': '500k كوينز', 'costValue': 500000, 'days': 365, 'icon': Icons.diamond, 'iconColor': Colors.cyanAccent},
    ];
    return _buildPlanList(plans, 'coins', userData, usd);
  }

  Widget _buildFinancialPlans(UserModel userData, double usd) {
    final plans = [
      {'title': 'باقة البداية', 'profit': 'عائد 10% شهرياً', 'cost': '100 \$', 'costValue': 100, 'days': 30, 'icon': Icons.attach_money, 'iconColor': Colors.greenAccent},
      {'title': 'باقة الأعمال', 'profit': 'عائد 12% شهرياً', 'cost': '250 \$', 'costValue': 250, 'days': 30, 'icon': Icons.business_center, 'iconColor': Colors.blueAccent},
      {'title': 'الباقة الاحترافية', 'profit': 'عائد 13.5% شهرياً', 'cost': '350 \$', 'costValue': 350, 'days': 30, 'icon': Icons.trending_up, 'iconColor': Colors.purpleAccent},
      {'title': 'باقة Royal Door', 'profit': 'عائد 20% شهرياً', 'cost': '1000 \$', 'costValue': 1000, 'days': 30, 'icon': Icons.auto_awesome, 'iconColor': Colors.amber},
    ];
    return _buildPlanList(plans, 'financial', userData, usd);
  }

  Widget _buildPlanList(List<Map<String, dynamic>> plans, String type, UserModel userData, double usd) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(userData.uid).collection('investments').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, invSnapshot) {
        final activeInvestments = invSnapshot.data?.docs.map((d) => d.data() as Map<String, dynamic>).toList() ?? [];

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            final activePlan = activeInvestments.firstWhere((inv) => inv['title'] == plan['title'], orElse: () => {});
            
            return _buildPlanCard(plan, type, userData, activePlan, usd);
          },
        );
      }
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, String type, UserModel userData, Map<String, dynamic> activePlan, double usd) {
    bool hasActive = activePlan.isNotEmpty;
    Timestamp? endTime = hasActive ? activePlan['endTime'] as Timestamp : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (plan['iconColor'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(plan['icon'], color: plan['iconColor'], size: 28)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(plan['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text(plan['profit'], style: TextStyle(color: plan['iconColor'], fontSize: 13))])),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(plan['cost'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: hasActive ? null : () => _handleStartInvestment(plan, type, userData, usd),
                    style: ElevatedButton.styleFrom(backgroundColor: hasActive ? Colors.white12 : Colors.white.withOpacity(0.1), minimumSize: const Size(80, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(hasActive ? 'نشط' : 'بدء', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          if (hasActive && endTime != null) ...[
            const SizedBox(height: 15),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الوقت المتبقي:', style: TextStyle(color: Colors.white24, fontSize: 11)),
                Text(_getRemainingTime(endTime), style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, {required this.bgColor});
  final TabBar _tabBar;
  final Color bgColor;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: bgColor, child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}
