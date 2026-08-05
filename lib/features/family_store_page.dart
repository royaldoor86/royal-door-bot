import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
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

class _FamilyStorePageState extends State<FamilyStorePage>
    with TickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  late TabController _tabController;
  late TabController _idCategoryTabController;
  final List<String> _idCategories = [
    'مقترح',
    'الأفضل',
    'ملحمي',
    'نادر',
    'شائع',
    'ملكي'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _idCategoryTabController =
        TabController(length: _idCategories.length, vsync: this);
    _idCategoryTabController.addListener(() {
      if (!_idCategoryTabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idCategoryTabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  Map<String, dynamic> _getRarityColors(String category) {
    switch (category) {
      case 'مقترح':
        return {
          'gradient': [const Color(0xFF00E5FF), const Color(0xFF00B8D4)],
          'border': Colors.white.withValues(alpha: 0.4),
          'iconColor': const Color(0xFF00B8D4),
          'glow': const Color(0xFF00E5FF),
        };
      case 'الأفضل':
        return {
          'gradient': [const Color(0xFFFFA726), const Color(0xFFF57C00)],
          'border': Colors.white.withValues(alpha: 0.4),
          'iconColor': const Color(0xFFF57C00),
          'glow': const Color(0xFFFB8C00),
        };
      case 'شائع':
        return {
          'gradient': [const Color(0xFF6EC6FF), const Color(0xFF2196F3)],
          'border': Colors.white.withValues(alpha: 0.3),
          'iconColor': const Color(0xFF2196F3),
          'glow': const Color(0xFF2196F3),
        };
      case 'نادر':
        return {
          'gradient': [const Color(0xFFB67DFF), const Color(0xFF8B44FF)],
          'border': Colors.white.withValues(alpha: 0.3),
          'iconColor': const Color(0xFF8B44FF),
          'glow': const Color(0xFF9C27B0),
        };
      case 'ملحمي':
        return {
          'gradient': [const Color(0xFFFF8EC7), const Color(0xFFFF4081)],
          'border': const Color(0xFFFFD700).withValues(alpha: 0.8),
          'iconColor': const Color(0xFFFF4081),
          'glow': const Color(0xFFE91E63),
        };
      case 'ملكي':
        return {
          'gradient': [const Color(0xFFF44336), const Color(0xFFD32F2F)],
          'border': const Color(0xFFFFD700),
          'iconColor': const Color(0xFFD32F2F),
          'glow': const Color(0xFFFFD700),
        };
      default:
        return {
          'gradient': [const Color(0xFF6EC6FF), const Color(0xFF2196F3)],
          'border': Colors.white.withValues(alpha: 0.3),
          'iconColor': const Color(0xFF2196F3),
          'glow': const Color(0xFF2196F3),
        };
    }
  }

  Widget _buildIDCircleIcon(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(Icons.diamond, color: color, size: 14),
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
          _wealthItem(family.familyCoins, Icons.monetization_on, Colors.amber,
              'كوينز الخزينة 🪙'),
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
            'هل تريد شراء "${item.name}" مقابل $actualCost ${item.currency == 'family_gems' ? 'جوهرة' : 'كوين'} من خزينة العائلة؟',
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
                  // إجبار تحديث الصفحة لعرض الإيدي الجديد
                  setState(() {});
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
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white38,
            tabs: const [
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
                  final family = FamilyModel.fromFirestore(
                      snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);
                  return Column(
                    children: [
                      _buildWealthHeader(family),
                      const SizedBox(height: 10),
                      _buildFeaturedItemsSection(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {
                            _searchTerm = value.trim();
                          }),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن عنصر أو إيدي...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Colors.white10)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Colors.white10)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStoreItemsTab('badge'),
                    _buildStoreItemsTab('perk'),
                    _buildHandIdTab(),
                    _buildStoreItemsTab('hand_effect'),
                    _buildStoreItemsTab('entertainment'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedItemsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('family_store_items')
          .where('isFeatured', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('isSold', isEqualTo: false)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final featuredItems = snapshot.data!.docs
            .map((doc) => FamilyStoreItemModel.fromFirestore(doc))
            .toList();

        if (featuredItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'عناصر مميزة',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredItems.length,
                  itemBuilder: (context, index) {
                    final item = featuredItems[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(left: 12),
                      child: _buildFeaturedItemCard(item),
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

  Widget _buildFeaturedItemCard(FamilyStoreItemModel item) {
    final bool hasSale = item.saleCost != null && item.saleCost! > 0;
    final int displayCost = hasSale ? item.saleCost! : item.cost;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withValues(alpha: 0.3),
            Colors.orange.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured badge
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'مميز',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Item image
            if (item.imageUrl.isNotEmpty)
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white10,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white38,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Item name
            Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Price
            Row(
              children: [
                Text(
                  '$displayCost',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.currency == 'family_gems' ? '💎' : '🪙',
                  style: const TextStyle(fontSize: 12),
                ),
                if (hasSale) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${item.cost}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ],
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
            .where((item) {
          if (_searchTerm.isEmpty) return true;
          final query = _searchTerm.toLowerCase();
          return item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query) ||
              item.type.toLowerCase().contains(query);
        }).toList();

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

  Widget _buildHandIdTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: TabBar(
            controller: _idCategoryTabController,
            isScrollable: true,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white38,
            tabs: _idCategories.map((category) => Tab(text: category)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _idCategoryTabController,
            children: _idCategories.map((category) {
              return StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('family_store_items')
                    .where('type', isEqualTo: 'hand_id')
                    .where('isActive', isEqualTo: true)
                    .where('category', isEqualTo: category)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!.docs
                      .map((doc) => FamilyStoreItemModel.fromFirestore(doc))
                      .where((item) {
                    if (_searchTerm.isEmpty) return true;
                    final query = _searchTerm.toLowerCase();
                    return item.name.toLowerCase().contains(query) ||
                        item.description.toLowerCase().contains(query) ||
                        item.category?.toLowerCase().contains(query) == true;
                  }).toList();

                  if (items.isEmpty) {
                    return const Center(
                        child: Text('لا توجد أيديات في هذه الفئة',
                            style: TextStyle(color: Colors.white38)));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 35,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildHandIdCard(item);
                    },
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreItemCard(FamilyStoreItemModel item) {
    final bool hasSale = item.saleCost != null && item.saleCost! > 0;
    final int displayCost = hasSale ? item.saleCost! : item.cost;
    final bool isUniqueItem =
        item.type == 'hand_id' || item.type == 'hand_effect';
    final bool isSoldUnique = item.isSold && isUniqueItem;
    final bool available = item.isActive && !isSoldUnique;

    return Stack(
      children: [
        AppTheme.glassContainer(
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
              if (item.purchaseCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'المشتريات: ${item.purchaseCount}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
              if (hasSale)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('عرض خاص',
                        style:
                            TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                  ),
                ),
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
                                color:
                                    hasSale ? Colors.cyanAccent : Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                        const SizedBox(width: 2),
                        Icon(
                            item.currency == 'family_gems'
                                ? Icons.diamond
                                : Icons.monetization_on,
                            size: 12,
                            color: item.currency == 'family_gems'
                                ? Colors.cyan
                                : Colors.amber),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: available ? () => _purchaseItem(item) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          available ? Colors.amber : Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      minimumSize: const Size(45, 28),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isSoldUnique ? 'تم البيع' : 'شراء',
                        style: TextStyle(
                            color: available ? Colors.black : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isSoldUnique)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('تم البيع',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemImageDisplay(FamilyStoreItemModel item) {
    // For badges, use the media-aware display
    if (item.type == 'badge') {
      return _buildBadgeMediaDisplay(item);
    }

    // For other items, use the original image display
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

  Widget _buildBadgeMediaDisplay(FamilyStoreItemModel item) {
    if (item.imageUrl.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: const Icon(Icons.badge, color: Colors.amber, size: 20),
      );
    }

    final mediaType = item.mediaType?.toLowerCase() ?? 'image';

    switch (mediaType) {
      case 'lottie':
        return SizedBox(
          width: 40,
          height: 40,
          child: Lottie.network(
            item.imageUrl,
            fit: BoxFit.contain,
            animate: false,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.error_outline,
                    color: Colors.white38, size: 20),
              );
            },
          ),
        );
      case 'video':
        return _BadgeVideoPlayer(videoUrl: item.imageUrl);
      case 'png':
      case 'image':
      default:
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
                child: const Icon(Icons.broken_image,
                    color: Colors.white38, size: 20),
              );
            },
          ),
        );
    }
  }

  Widget _buildHandIdCard(FamilyStoreItemModel item) {
    final handNumber = item.handNumber;
    final handLetters = item.handLetters;
    final category = item.category ?? 'شائع';
    final int? salePrice = item.saleCost;
    final price = salePrice != null && salePrice > 0 ? salePrice : item.cost;
    final currency = item.currency;
    final bool isSold = item.isSold;
    final bool available = item.isActive && !isSold;

    final rarityColors = _getRarityColors(category);
    final royalId = handNumber ?? handLetters ?? '---';

    return GestureDetector(
      onTap: available ? () => _purchaseItem(item) : null,
      child: Stack(
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rarityColors['border'] as Color,
                width: (category == 'ملكي' || category == 'ملحمي') ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: rarityColors['gradient'] as List<Color>,
                    ),
                  ),
                ),
                // Content
                Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                royalId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildIDCircleIcon(
                                rarityColors['iconColor'] as Color),
                          ],
                        ),
                      ),
                    ),
                    // Price Bar
                    Container(
                      height: 24,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$price',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            currency == 'family_gems'
                                ? Icons.diamond
                                : Icons.monetization_on,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  Widget _BadgeVideoPlayer({required String videoUrl}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: VideoPlayerWidget(videoUrl: videoUrl),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white38,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
