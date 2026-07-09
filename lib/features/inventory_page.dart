import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_store_item_model.dart';
import '../theme/app_theme.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A050E),
      appBar: AppBar(
        title: const Text('محفظتي',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3D0B16), Color(0xFF1A050E)])),
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              _db.collection('users').doc(_auth.currentUser?.uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final inventory = List<String>.from(userData['inventory'] ?? []);

            if (inventory.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2, size: 64, color: Colors.white38),
                    SizedBox(height: 16),
                    Text(
                      'محفظتك فارغة',
                      style: TextStyle(color: Colors.white38, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اشترِ عناصر من المتجر لإضافتها هنا',
                      style: TextStyle(color: Colors.white24, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return FutureBuilder<QuerySnapshot>(
              future: _db
                  .collection('family_store_items')
                  .where(FieldPath.documentId, whereIn: inventory)
                  .get(),
              builder: (context, itemSnapshot) {
                if (!itemSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = itemSnapshot.data!.docs
                    .map((doc) => FamilyStoreItemModel.fromFirestore(
                        doc as DocumentSnapshot<Map<String, dynamic>>))
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildInventoryItemCard(item);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInventoryItemCard(FamilyStoreItemModel item) {
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

    // عرض الصورة/فيديو/GIF بشكل أكبر
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
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandIdDisplay(FamilyStoreItemModel item) {
    final handNumber = item.handNumber;
    final handLetters = item.handLetters;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withValues(alpha: 0.2),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (handNumber != null && handNumber.isNotEmpty)
              Text(handNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            if (handLetters != null && handLetters.isNotEmpty)
              Text(handLetters,
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHandEffectDisplay(FamilyStoreItemModel item) {
    final handNumber = item.handNumber;
    final handLetters = item.handLetters;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.purple.withValues(alpha: 0.2),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (handNumber != null && handNumber.isNotEmpty)
              Text(handNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            if (handLetters != null && handLetters.isNotEmpty)
              Text(handLetters,
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _getTypeBadge(String type) {
    String label;
    Color color;

    switch (type) {
      case 'badge':
        label = 'شارة';
        color = Colors.blue;
        break;
      case 'perk':
        label = 'ميزة';
        color = Colors.orange;
        break;
      case 'hand_id':
        label = 'إيد';
        color = Colors.green;
        break;
      case 'hand_effect':
        label = 'تأثير';
        color = Colors.purple;
        break;
      case 'entertainment':
        label = 'ترفيه';
        color = Colors.pink;
        break;
      default:
        label = type;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
