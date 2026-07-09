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
    final int actualCost = (item.saleCost != null && item.saleCost! > 0)
        ? item.saleCost!
        : item.cost;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title:
            const Text('تأكيد الشراء', style: TextStyle(color: Colors.white)),
        content: Text(
            'هل تريد شراء "${item.name}" مقابل $actualCost ${item.currency == 'family_gems' ? 'جوهرة' : 'نجمة ⭐'} من خزينة العائلة؟',
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
    return DefaultTabController(
      length: 5,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('متجر العائلة الملكي',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: const TabBar(
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white38,
              tabs: [
                Tab(text: 'الشارات'),
                Tab(text: 'المزايا'),
                Tab(text: 'الإيديات'),
                Tab(text: 'التأثيرات'),
                Tab(text: 'الترفيه'),
              ],
            ),
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
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final family = FamilyModel.fromFirestore(snapshot.data!
                        as DocumentSnapshot<Map<String, dynamic>>);
                    return _buildWealthHeader(family);
                  },
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildStoreItemsTab('badge'),
                      _buildStoreItemsTab('perk'),
                      _buildStoreItemsTab('hand_id'),
                      _buildStoreItemsTab('hand_effect'),
                      _buildStoreItemsTab('entertainment'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreItemsTab(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('family_store_items')
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  Widget _buildStoreItemCard(FamilyStoreItemModel item) {
    final bool hasSale = item.saleCost != null && item.saleCost! > 0;
    final int displayCost = hasSale ? item.saleCost! : item.cost;

    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.type == 'hand_id')
            _buildHandIdDisplay(item)
          else if (item.type == 'hand_effect')
            _buildHandEffectDisplay(item)
          else
            _buildItemImageDisplay(item),
          const SizedBox(height: 8),
          Text(item.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(item.description,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          _getTypeBadge(item.type),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (hasSale) ...[
                      Text('${item.cost}',
                          style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 9,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 4),
                    ],
                    Text('$displayCost',
                        style: TextStyle(
                            color: hasSale ? Colors.cyanAccent : Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                    const SizedBox(width: 2),
                    Icon(
                        item.currency == 'family_gems'
                            ? Icons.diamond
                            : (item.currency == 'family_coins'
                                ? Icons.monetization_on
                                : Icons.stars_rounded),
                        size: 12,
                        color: item.currency == 'family_gems'
                            ? Colors.cyan
                            : Colors.amber),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _purchaseItem(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(45, 28),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('شراء',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemImageDisplay(FamilyStoreItemModel item) {
    if (item.imageUrl.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: const Icon(Icons.shopping_bag, color: Colors.amber, size: 20),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        item.imageUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child:
                const Icon(Icons.broken_image, color: Colors.white38, size: 20),
          );
        },
      ),
    );
  }

  Widget _buildHandIdDisplay(FamilyStoreItemModel item) {
    final handNumber = item.handNumber;
    final handLetters = item.handLetters;

    return Center(
      child: Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black54, Colors.black87],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.8),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (handNumber != null && handNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  handNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            if (handLetters != null && handLetters.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  handLetters,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandEffectDisplay(FamilyStoreItemModel item) {
    final handNumber = item.handNumber;
    final handLetters = item.handLetters;

    return Center(
      child: Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black54, Colors.black87],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.purpleAccent.withValues(alpha: 0.8),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (handNumber != null && handNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  handNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            if (handLetters != null && handLetters.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  handLetters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getTypeBadge(String type) {
    switch (type) {
      case 'perk':
        return _badgeContainer('ميزة', Colors.blue);
      case 'hand_id':
        return _badgeContainer('إيديات', Colors.purple);
      case 'hand_effect':
        return _badgeContainer('تأثير', Colors.pink);
      case 'entertainment':
        return _badgeContainer('ترفيه', Colors.orange);
      case 'badge':
        return _badgeContainer('شارة', Colors.green);
      default:
        return const SizedBox();
    }
  }

  Widget _badgeContainer(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
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
