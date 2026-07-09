import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_model.dart';
import '../user_details_view_page.dart';

class PartnerItem extends StatefulWidget {
  final UserModel partner;
  final bool isOnline;
  const PartnerItem({super.key, required this.partner, this.isOnline = false});

  @override
  State<PartnerItem> createState() => _PartnerItemState();
}

class _PartnerItemState extends State<PartnerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => UserDetailsViewPage(user: widget.partner)));
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.pinkAccent, shape: BoxShape.circle),
                    child: Hero(
                      tag:
                          'profilePic_${widget.partner.name}_${widget.partner.profilePic}',
                      child: CircleAvatar(
                          radius: 35,
                          backgroundImage: widget
                                  .partner.profilePic.isNotEmpty
                              ? NetworkImage(widget.partner.profilePic)
                              : const AssetImage(
                                      'assets/images/avatar_placeholder.png')
                                  as ImageProvider),
                    ),
                  ),
                  // الأيقونات السفلية (حالة الاتصال + VIP)
                  Positioned(
                    bottom: 4,
                    right: 18,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // حالة الاتصال
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color:
                                widget.isOnline ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // استخدام صور الـ VIP الموجودة فعلياً في مجلد assets/vip/
                        if (widget.partner.userLevel >= 1)
                          Image.asset('assets/vip/1.png',
                              width: 18, height: 18, 
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1.5)),
                  child: Text('LV.${widget.partner.userLevel}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)))
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.partner.name,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87))
        ]),
      ),
    );
  }
}
