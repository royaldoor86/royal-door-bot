import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';

class UserGiftsPage extends StatefulWidget {
  final String userId;
  const UserGiftsPage({super.key, required this.userId});

  @override
  State<UserGiftsPage> createState() => _UserGiftsPageState();
}

class _UserGiftsPageState extends State<UserGiftsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'هدايا الغرف الملكية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('sent_gifts')
              .where('receiverId', isEqualTo: widget.userId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.royalGold),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'لم يتم استلام هدايا ملكية بعد',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final gifts = snapshot.data!.docs;
            Map<String, Map<String, dynamic>> groupedGifts = {};

            for (var doc in gifts) {
              final data = doc.data() as Map<String, dynamic>;
              final giftId = data['giftId'];
              if (groupedGifts.containsKey(giftId)) {
                groupedGifts[giftId]!['count'] =
                    (groupedGifts[giftId]!['count'] ?? 0) +
                        (data['count'] ?? 1);
              } else {
                groupedGifts[giftId] = {
                  'name': data['giftName'],
                  'imageUrl': data['giftImage'],
                  'count': data['count'] ?? 1,
                  'senderId': data['senderId'],
                  'senderName': data['senderName'],
                  'senderPic': data['senderPic'],
                };
              }
            }

            final uniqueGifts = groupedGifts.values.toList();

            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemCount: uniqueGifts.length,
              itemBuilder: (context, index) {
                final gift = uniqueGifts[index];
                return _buildGiftCard(gift);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGiftCard(Map<String, dynamic> gift) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: gift['imageUrl'] != null && gift['imageUrl'].isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: gift['imageUrl'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.white10,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.royalGold,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.card_giftcard,
                              size: 50,
                              color: Colors.white24,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.white10,
                          child: const Icon(
                            Icons.card_giftcard,
                            size: 50,
                            color: Colors.white24,
                          ),
                        ),
                ),
                if (gift['count'] != null && gift['count'] > 1)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x${gift['count']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift['name'] ?? 'هدية ملكية',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (gift['senderName'] != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: gift['senderPic'] != null &&
                                gift['senderPic'].isNotEmpty
                            ? NetworkImage(gift['senderPic'])
                            : null,
                        child: gift['senderPic'] == null ||
                                gift['senderPic'].isEmpty
                            ? const Icon(Icons.person,
                                size: 12, color: Colors.white24)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          gift['senderName'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
}
