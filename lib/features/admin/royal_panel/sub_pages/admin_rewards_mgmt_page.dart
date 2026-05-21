import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../constants/rewards_constants.dart';

class AdminRewardsMgmtPage extends StatefulWidget {
  final String type; // 'coins', 'gems', 'financial', 'rewards'
  const AdminRewardsMgmtPage({super.key, required this.type});

  @override
  State<AdminRewardsMgmtPage> createState() =>
      _AdminRewardsMgmtPageState();
}

class _AdminRewardsMgmtPageState extends State<AdminRewardsMgmtPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFF0A1F1C);

  @override
  Widget build(BuildContext context) {
    String title = widget.type == 'coins'
        ? 'إدارة مزايا النجوم ⭐'
        : (widget.type == 'gems'
            ? 'إدارة مزايا الجواهر'
            : (widget.type == 'rewards'
                ? 'الحصاد الملكي'
                : 'إدارة المزايا (نجوم)'));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text(title,
              style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          actions: [
            // زر توليد الباقات تلقائياً
            IconButton(
              tooltip: 'توليد الباقات الافتراضية',
              icon: const Icon(Icons.auto_awesome, color: Colors.orangeAccent),
              onPressed: () => _seedDefaultPackages(),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Colors.greenAccent),
              onPressed: () => _showAddPackageDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.account_balance_wallet,
                  color: Colors.amberAccent),
              onPressed: () => _showRechargeUserDialog(),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection(RewardsConstants.collectionPackages)
              .where('type', isEqualTo: widget.type)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final packages = snapshot.data!.docs;
            if (packages.isEmpty) {
              return const Center(
                  child: Text(
                      'لا توجد باقات حالياً. اضغط على النجمة لتوليدها!',
                      style: TextStyle(color: Colors.white54)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final pkg = packages[index].data() as Map<String, dynamic>;
                final docId = packages[index].id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: goldColor.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.inventory_2_outlined, color: goldColor),
                    title: Text(pkg[RewardsConstants.fieldTitle] ?? pkg['title'] ?? 'بدون عنوان',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'التكلفة: ${pkg[RewardsConstants.fieldCost] ?? pkg['cost']} | النمو اليومي: ${pkg[RewardsConstants.fieldDailyReward] ?? pkg['dailyReward'] ?? pkg['dailyProfit'] ?? pkg['weeklyProfit']}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        Text('إجمالي المزايا: ${pkg[RewardsConstants.fieldTotalReward] ?? pkg['totalReward'] ?? pkg['totalProfit']}',
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent, size: 20),
                            onPressed: () => _showAddPackageDialog(
                                docId: docId, existingData: pkg)),
                        IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent, size: 20),
                            onPressed: () => _deletePackage(docId)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _seedDefaultPackages() async {
    final List<Map<String, dynamic>> financialSeeds = [
      {'cost': 100, 'dr': '0.3%', 'tr': '8%'},
      {'cost': 250, 'dr': '0.35%', 'tr': '10%'},
      {'cost': 500, 'dr': '0.4%', 'tr': '12%'},
      {'cost': 750, 'dr': '0.45%', 'tr': '14%'},
      {'cost': 1000, 'dr': '0.5%', 'tr': '16%'},
      {'cost': 1200, 'dr': '0.6%', 'tr': '18%'},
      {'cost': 1500, 'dr': '0.7%', 'tr': '20%'},
      {'cost': 2000, 'dr': '0.8%', 'tr': '22%'},
      {'cost': 5000, 'dr': '0.9%', 'tr': '26%'},
      {'cost': 7500, 'dr': '1.0%', 'tr': '30%'},
      {'cost': 10000, 'dr': '1.2%', 'tr': '34%'},
    ];

    final List<num> creditSeeds = [
      50000,
      100000,
      250000,
      500000,
      750000,
      1000000
    ];

    try {
      if (!context.mounted) return;
      if (widget.type == 'financial') {
        for (var seed in financialSeeds) {
          await _db.collection(RewardsConstants.collectionPackages).add({
            RewardsConstants.fieldTitle: 'باقة النخبة ${seed['cost']} نجمة',
            RewardsConstants.fieldCost: seed['cost'],
            RewardsConstants.fieldDailyReward: seed['dr'],
            RewardsConstants.fieldTotalReward: seed['tr'],
            RewardsConstants.fieldDurationDays: 30,
            'type': 'financial',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        double startDr = 0.5;
        for (var cost in creditSeeds) {
          await _db.collection(RewardsConstants.collectionPackages).add({
            RewardsConstants.fieldTitle: 'باقة ملكية $cost',
            RewardsConstants.fieldCost: cost,
            RewardsConstants.fieldDailyReward: '$startDr%',
            RewardsConstants.fieldTotalReward: '${startDr * 30}%',
            RewardsConstants.fieldDurationDays: 30,
            'type': widget.type,
            'createdAt': FieldValue.serverTimestamp(),
          });
          startDr += 0.1;
        }
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم توليد الباقات بنجاح ✨'),
          backgroundColor: Colors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التوليد')));
    }
  }

  void _showAddPackageDialog(
      {String? docId, Map<String, dynamic>? existingData}) {
    final titleController = TextEditingController(text: existingData?[RewardsConstants.fieldTitle] ?? existingData?['title']);
    final costController =
        TextEditingController(text: (existingData?[RewardsConstants.fieldCost] ?? existingData?['cost'])?.toString());
    final dailyRewardController =
        TextEditingController(text: existingData?[RewardsConstants.fieldDailyReward] ?? existingData?['dailyReward'] ?? existingData?['dailyProfit'] ?? existingData?['weeklyProfit']);
    final totalRewardController =
        TextEditingController(text: existingData?[RewardsConstants.fieldTotalReward] ?? existingData?['totalReward'] ?? existingData?['totalProfit']);
    final daysController =
        TextEditingController(text: (existingData?[RewardsConstants.fieldDurationDays] ?? existingData?['days'])?.toString() ?? '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF051211),
        title: Text(docId == null ? 'إضافة باقة حصاد' : 'تعديل باقة',
            style: TextStyle(color: goldColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(titleController, 'اسم الباقة'),
              _buildField(costController, 'التكلفة',
                  keyboardType: TextInputType.number),
              _buildField(dailyRewardController, 'النمو اليومي (مثلاً 0.5%)'),
              _buildField(totalRewardController, 'إجمالي المزايا (مثلاً 15%)'),
              _buildField(daysController, 'عدد الأيام',
                  keyboardType: TextInputType.number),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'تنبيه: جميع المزايا افتراضية وليس لها قيمة مادية حقيقية داخل أو خارج التطبيق.',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () async {
              final data = {
                RewardsConstants.fieldTitle: titleController.text,
                RewardsConstants.fieldCost: num.tryParse(costController.text) ?? 0,
                RewardsConstants.fieldDailyReward: dailyRewardController.text,
                RewardsConstants.fieldTotalReward: totalRewardController.text,
                RewardsConstants.fieldDurationDays: int.tryParse(daysController.text) ?? 30,
                'type': widget.type,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (docId == null) {
                await _db.collection(RewardsConstants.collectionPackages).add(data);
              } else {
                await _db
                    .collection(RewardsConstants.collectionPackages)
                    .doc(docId)
                    .update(data);
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: goldColor),
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showRechargeUserDialog() {
    final royalIdController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF051211),
        title: Text(
            widget.type == 'rewards'
                ? 'شحن محفظة المكافآت الملكية'
                : 'شحن محفظة مكافآت ${widget.type}',
            style: TextStyle(color: goldColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(royalIdController, 'الآيدي الملكي للمستخدم'),
            _buildField(amountController, 'المبلغ',
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () async {
              final snap = await _db
                  .collection('users')
                  .where('royalId', isEqualTo: royalIdController.text)
                  .limit(1)
                  .get();
              if (!context.mounted) return;
              if (snap.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('المستخدم غير موجود')));
                return;
              }
              final userDoc = snap.docs.first;
              final amount = num.tryParse(amountController.text) ?? 0;
              final walletField = widget.type == 'coins'
                  ? 'rewards_wallet_stars'
                  : (widget.type == 'gems'
                      ? RewardsConstants.walletGemsField
                      : (widget.type == 'rewards'
                          ? RewardsConstants.walletGemsField
                          : RewardsConstants.walletStarsField));

              await _db
                  .collection('users')
                  .doc(userDoc.id)
                  .update({
                    walletField: FieldValue.increment(amount),
                    if (walletField == RewardsConstants.walletGemsField) 'rewards_wallet_gems': FieldValue.increment(amount), // Sync
                    if (walletField == RewardsConstants.walletStarsField) 'rewards_wallet_stars': FieldValue.increment(amount), // Sync
                    if (walletField == 'rewards_wallet_stars') 'rewards_wallet_stars_legacy': FieldValue.increment(amount), // Legacy Sync if needed
                    'harvest_wallet': FieldValue.increment(amount), // Backward compatibility
                  });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تم الشحن بنجاح ✅'),
                  backgroundColor: Colors.green));
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            child:
                const Text('شحن الآن', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePackage(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title:
            const Text('حذف الباقة', style: TextStyle(color: Colors.redAccent)),
        content: const Text('هل أنت متأكد من حذف باقة الحصاد هذه؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection(RewardsConstants.collectionPackages).doc(id).delete();
    }
  }

  Widget _buildField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24)),
          focusedBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
        ),
      ),
    );
  }
}
