import 'package:flutter/material.dart';

class RankBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isTextOnly;
  const RankBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isTextOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 4)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!isTextOnly && icon != null)
          Icon(icon, color: Colors.white, size: 11),
        if (!isTextOnly && icon != null) const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
      ]),
    );
  }
}
