import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/story_model.dart';
import '../../../app_theme.dart';

class StoryCard extends StatelessWidget {
  final List<StoryModel> group;
  final VoidCallback onTap;
  final bool isAddButton;

  const StoryCard({
    super.key,
    required this.group,
    required this.onTap,
    this.isAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    if (isAddButton) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 75,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white24, size: 35),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.royalGold, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.black, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'قصتي',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final first = group.first;
    // التحقق مما إذا كانت جميع القصص في المجموعة قد شوهدت
    final bool allViewed = group.every((s) => s.viewers.contains(currentUid));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: allViewed
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                border: allViewed ? Border.all(color: Colors.white24, width: 1.5) : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: ClipOval(
                  child: (first.userPic.isNotEmpty && Uri.tryParse(first.userPic)?.host.isNotEmpty == true)
                    ? CachedNetworkImage(
                        imageUrl: first.userPic,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.white10),
                        errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white24),
                      )
                    : (first.imageUrl != null && first.imageUrl!.isNotEmpty && Uri.tryParse(first.imageUrl!)?.host.isNotEmpty == true)
                      ? CachedNetworkImage(
                          imageUrl: first.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.white10),
                          errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white24),
                        )
                      : const Icon(Icons.person, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              first.userName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: allViewed ? Colors.white38 : Colors.white,
                fontSize: 11,
                fontWeight: allViewed ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
