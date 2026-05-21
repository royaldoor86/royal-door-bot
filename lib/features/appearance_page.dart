import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/animated_vehicle_preview.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _previewFrame; 
  String? _previewBadge; 
  String? _previewEntryEffect; 
  Map<String, String>? _previewVehicle;
  String? _previewBubble;
  String? _previewCover;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _applyAppearance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic> updates = {};
    if (_previewFrame != null) updates['currentFrame'] = _previewFrame;
    if (_previewBadge != null) updates['activeBadge'] = _previewBadge;
    if (_previewEntryEffect != null) updates['entryEffect'] = _previewEntryEffect;
    if (_previewBubble != null) updates['chatBubble'] = _previewBubble;
    if (_previewCover != null) updates['profileCover'] = _previewCover;
    
    if (_previewVehicle != null) {
      updates['activeVehicleUrl'] = _previewVehicle!['url'];
      updates['activeVehicleType'] = _previewVehicle!['type'];
    }

    if (updates.isNotEmpty) {
      try {
        await _db.collection('users').doc(user.uid).update(updates);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تفعيل المظهر الملكي الجديد بنجاح! 👑✨'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _previewFrame = null;
            _previewBadge = null;
            _previewVehicle = null;
            _previewEntryEffect = null;
            _previewBubble = null;
            _previewCover = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
        }
      }
    }
  }

  Future<void> _deleteInventoryItem(String docId, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف مقتنى', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('هل تريد حذف هذا العنصر نهائياً من مقتنياتك؟ لا يمكن التراجع عن هذا الإجراء.', 
          style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('users').doc(user.uid).collection('inventory').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<UserModel>(
        stream: userAuth != null ? _firestoreService.streamUserData(userAuth.uid) : null,
        builder: (context, snapshot) {
          final userData = snapshot.data;
          if (!snapshot.hasData) return const Scaffold(backgroundColor: Color(0xFF021412), body: Center(child: CircularProgressIndicator(color: Colors.amber)));

          return Scaffold(
            backgroundColor: const Color(0xFF021412),
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildLivePreviewBox(userData!),
                  _buildTabs(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInventorySection(userData, 'frame', 'الإطارات'),
                        _buildInventorySection(userData, 'badge', 'الشارات'),
                        _buildInventorySection(userData, 'vehicle', 'المركبات'),
                        _buildInventorySection(userData, 'entry_effect', 'المؤثرات'),
                        _buildInventorySection(userData, 'cover', 'الأغلفة'),
                        _buildInventorySection(userData, 'bubble', 'الفقاعات'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          const Text('مظهري الملكي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
        ],
      ),
    );
  }

  Widget _buildLivePreviewBox(UserModel userData) {
    String displayFrame = _previewFrame ?? userData.currentFrame ?? '';
    String? displayBadge = _previewBadge ?? userData.activeBadge;
    String? displayEffect = _previewEntryEffect ?? userData.entryEffect;
    
    return Container(
      width: double.infinity,
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(30),
        border:
            Border.all(color: Colors.amber.withValues(alpha: 0.2), width: 1.5),
        image: ((_previewCover != null &&
                        Uri.tryParse(_previewCover!)?.host.isNotEmpty ==
                            true) ||
                    (userData.agentData?['profileCover'] != null &&
                        Uri.tryParse(userData.agentData?['profileCover'])
                                ?.host
                                .isNotEmpty ==
                            true))
            ? DecorationImage(
                image: NetworkImage(_previewCover ??
                    userData.agentData?['profileCover'] ??
                    ''),
                fit: BoxFit.cover,
                opacity: 0.3,
              )
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_previewVehicle != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Opacity(
                  opacity: 0.6,
                  child: AnimatedVehiclePreview(
                    type: _previewVehicle!['type']!, 
                    url: _previewVehicle!['url']!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          if (displayEffect != null &&
              displayEffect.isNotEmpty &&
              Uri.tryParse(displayEffect)?.host.isNotEmpty == true)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.8,
                  child: displayEffect.contains('.json')
                      ? Lottie.network(displayEffect, fit: BoxFit.contain)
                      : CachedNetworkImage(
                          imageUrl: displayEffect, fit: BoxFit.contain),
                ),
              ),
            ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white10,
                    backgroundImage: (userData.profilePic.isNotEmpty &&
                            Uri.tryParse(userData.profilePic)?.host.isNotEmpty ==
                                true)
                        ? NetworkImage(userData.profilePic)
                        : null,
                    child: (userData.profilePic.isEmpty ||
                            Uri.tryParse(userData.profilePic)?.host.isEmpty ==
                                true)
                        ? const Icon(Icons.person, color: Colors.white24, size: 40)
                        : null,
                  ),
                  if (displayFrame.isNotEmpty &&
                      Uri.tryParse(displayFrame)?.host.isNotEmpty == true)
                    CachedNetworkImage(
                        imageUrl: displayFrame,
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(userData.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  if (displayBadge != null) ...[
                    const SizedBox(width: 8),
                    _buildBadgeDisplay(displayBadge),
                  ],
                ],
              ),
              if (_previewFrame != null || _previewVehicle != null || _previewBadge != null || _previewEntryEffect != null || _previewBubble != null || _previewCover != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: ElevatedButton(
                    onPressed: _applyAppearance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber, 
                      foregroundColor: Colors.black,
                      minimumSize: const Size(160, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 10,
                    ),
                    child: const Text('تفعيل المظهر الآن', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeDisplay(String badgeData) {
    bool isUrl = badgeData.startsWith('http');
    if (isUrl && Uri.tryParse(badgeData)?.host.isNotEmpty == true) {
      return CachedNetworkImage(
          imageUrl: badgeData, width: 22, height: 22, fit: BoxFit.contain);
    }
    return Text(badgeData, style: const TextStyle(fontSize: 18));
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: Colors.amber,
      labelColor: Colors.amber,
      unselectedLabelColor: Colors.white24,
      indicatorWeight: 3,
      tabs: const [
        Tab(text: 'الإطارات'),
        Tab(text: 'الشارات'),
        Tab(text: 'مركباتي'),
        Tab(text: 'المؤثرات'),
        Tab(text: 'الأغلفة'),
        Tab(text: 'الفقاعات'),
      ],
    );
  }

  Widget _buildInventorySection(UserModel userData, String type, String title) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(userData.uid).collection('inventory').where('type', isEqualTo: type).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final items = snapshot.data!.docs;

        if (items.isEmpty) {
          return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 50),
            const SizedBox(height: 10),
            Text('لا توجد $title مقتناة حالياً', style: const TextStyle(color: Colors.white24, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/store'), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.05)),
              child: const Text('اذهب للمتجر الملكي', style: TextStyle(color: Colors.amber, fontSize: 12)),
            )
          ],
        ));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index].data() as Map<String, dynamic>;
            return _buildItemCard(items[index].id, item, type, userData);
          },
        );
      }
    );
  }

  Widget _buildItemCard(String docId, Map<String, dynamic> item, String type, UserModel userData) {
    final String itemIcon = item['icon'] ?? item['imageUrl'] ?? '';
    
    // التحقق من الحالة النشطة في قاعدة البيانات
    final bool isCurrentActive = (type == 'frame' && userData.currentFrame == itemIcon) ||
                                (type == 'badge' && userData.activeBadge == itemIcon) ||
                                (type == 'entry_effect' && userData.entryEffect == itemIcon) ||
                                (type == 'vehicle' && userData.activeVehicleUrl == itemIcon);

    final bool isPreviewing = (type == 'frame' && _previewFrame == itemIcon) ||
                              (type == 'badge' && _previewBadge == itemIcon) ||
                              (type == 'entry_effect' && _previewEntryEffect == itemIcon) ||
                              (type == 'vehicle' && _previewVehicle?['url'] == itemIcon) ||
                              (type == 'bubble' && _previewBubble == itemIcon) ||
                              (type == 'cover' && _previewCover == itemIcon);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (type == 'frame') _previewFrame = item['imageUrl'];
          if (type == 'badge') _previewBadge = item['icon'];
          if (type == 'entry_effect') _previewEntryEffect = item['imageUrl'];
          if (type == 'bubble') _previewBubble = item['imageUrl'];
          if (type == 'cover') _previewCover = item['imageUrl'];
          if (type == 'vehicle') {
            _previewVehicle = {
              'url': item['imageUrl'], 
              'type': item['vehicleType'] ?? 'gif'
            };
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isPreviewing ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isPreviewing ? Colors.amber : (isCurrentActive ? Colors.green.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05)),
            width: isPreviewing || isCurrentActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (isCurrentActive)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomLeft: Radius.circular(10)),
                  ),
                  child: const Text('مفعل', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: _buildItemPreview(item, type),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['name'] ?? '', 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(
                        color: isPreviewing ? Colors.amber : Colors.white70, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => _deleteInventoryItem(docId, type),
                    child: Icon(Icons.delete_outline, color: Colors.redAccent.withValues(alpha: 0.5), size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemPreview(Map<String, dynamic> item, String type) {
    if (type == 'vehicle') {
      return AnimatedVehiclePreview(type: item['vehicleType'] ?? 'gif', url: item['imageUrl'], fit: BoxFit.contain);
    } else if (type == 'badge') {
      final String icon = item['icon'] ?? '';
      final bool isImage = item['isImage'] ?? icon.startsWith('http');
      if (isImage && Uri.tryParse(icon)?.host.isNotEmpty == true) {
        return CachedNetworkImage(imageUrl: icon, fit: BoxFit.contain);
      } else {
        return Center(child: Text(icon, style: const TextStyle(fontSize: 40)));
      }
    } else if (type == 'entry_effect') {
      final String url = item['imageUrl'] ?? '';
      if (Uri.tryParse(url)?.host.isNotEmpty == true) {
        return url.contains('.json')
            ? Lottie.network(url, fit: BoxFit.contain)
            : CachedNetworkImage(imageUrl: url, fit: BoxFit.contain);
      } else {
        return const Icon(Icons.image, color: Colors.white10);
      }
    } else {
      return (item['imageUrl'] != null &&
              Uri.tryParse(item['imageUrl'])?.host.isNotEmpty == true)
          ? CachedNetworkImage(imageUrl: item['imageUrl'], fit: BoxFit.contain)
          : const Icon(Icons.image, color: Colors.white10);
    }
  }
}
