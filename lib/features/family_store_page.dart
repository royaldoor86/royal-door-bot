import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/family_model.dart';
import '../models/family_store_item_model.dart';
import '../services/family_service.dart';
import '../app_theme.dart';

class FamilyStorePage extends StatefulWidget {
  final FamilyModel family;
  const FamilyStorePage({super.key, required this.family});

  @override
  State<FamilyStorePage> createState() => _FamilyStorePageState();
}

class _FamilyStorePageState extends State<FamilyStorePage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _purchaseItem(FamilyStoreItemModel item) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title:
            const Text('تأكيد الشراء', style: TextStyle(color: Colors.white)),
        content: Text(
            'هل تريد شراء "${item.name}" مقابل ${item.cost} ${item.currency == 'family_gems' ? 'جوهرة' : 'نجمة ⭐'} من خزينة العائلة؟',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _familyService.purchaseFamilyStoreItem(
                    widget.family.id, item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم الشراء بنجاح! 🎉')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('شراء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('متجر العائلة الملكي',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3D0B16), Color(0xFF1A050E)])),
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('families')
                    .doc(widget.family.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final family = FamilyModel.fromFirestore(
                      snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);
                  return _buildWealthHeader(family);
                },
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('family_store_items')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final items = snapshot.data!.docs
                        .map((doc) => FamilyStoreItemModel.fromFirestore(doc))
                        .toList();

                    if (items.isEmpty) {
                      return const Center(
                          child: Text('لا توجد عناصر حالياً',
                              style: TextStyle(color: Colors.white38)));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildStoreItemCard(item);
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

  Widget _buildStoreItemCard(FamilyStoreItemModel item) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                item.imageUrl.isNotEmpty ? NetworkImage(item.imageUrl) : null,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: item.imageUrl.isEmpty
                ? const Icon(Icons.shopping_bag, color: Colors.amber)
                : null,
          ),
          const SizedBox(height: 10),
          Text(item.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(item.description,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          _getTypeBadge(item.type),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${item.cost}',
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
              const SizedBox(width: 5),
              Icon(
                  item.currency == 'family_gems'
                      ? Icons.diamond
                      : Icons.stars_rounded,
                  size: 16,
                  color: item.currency == 'family_gems'
                      ? Colors.cyan
                      : Colors.amber),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _purchaseItem(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('شراء',
                    style: TextStyle(color: Colors.black, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getTypeBadge(String type) {
    switch (type) {
      case 'perk':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8)),
          child: const Text('ميزة',
              style: TextStyle(color: Colors.blue, fontSize: 10)),
        );
      case 'hand_effect':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8)),
          child: const Text('إيدات',
              style: TextStyle(color: Colors.purple, fontSize: 10)),
        );
      case 'entertainment':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8)),
          child: const Text('ترفيه',
              style: TextStyle(color: Colors.orange, fontSize: 10)),
        );
      case 'badge':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8)),
          child: const Text('شارة',
              style: TextStyle(color: Colors.green, fontSize: 10)),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildWealthHeader(FamilyModel family) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _wealthItem(family.familyGems, Icons.diamond, Colors.cyanAccent,
              'جواهر الخزينة'),
          _wealthItem(family.familyCoins, Icons.stars_rounded, Colors.amber,
              'نجوم ⭐ الخزينة'),
        ],
      ),
    );
  }

  Widget _wealthItem(int value, IconData icon, Color color, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(value.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
