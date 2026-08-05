import 'package:flutter/material.dart';
import '../models/privacy_model.dart';

/// Widget for selecting privacy level
class PrivacySelector extends StatelessWidget {
  final PrivacyLevel selectedPrivacy;
  final Function(PrivacyLevel) onPrivacyChanged;
  final String? title;

  const PrivacySelector({
    super.key,
    required this.selectedPrivacy,
    required this.onPrivacyChanged,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...PrivacyLevel.values.map((level) {
            return _buildPrivacyOption(
              context,
              level,
              selectedPrivacy == level,
              isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    BuildContext context,
    PrivacyLevel level,
    bool isSelected,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => onPrivacyChanged(level),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.purple.withValues(alpha: 0.2) : Colors.purple.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.purple : Colors.purple)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getPrivacyIcon(level),
              color: isSelected
                  ? (isDark ? Colors.purple : Colors.purple)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.arabicLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    _getPrivacyDescription(level),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark ? Colors.purple : Colors.purple,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getPrivacyIcon(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return Icons.public;
      case PrivacyLevel.friendsOnly:
        return Icons.group;
      case PrivacyLevel.friendsOfFriends:
        return Icons.people_outline;
    }
  }

  String _getPrivacyDescription(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return 'يمكن للجميع رؤية هذا المحتوى';
      case PrivacyLevel.friendsOnly:
        return 'يمكن لأصدقائك فقط رؤية هذا المحتوى';
      case PrivacyLevel.friendsOfFriends:
        return 'يمكن لأصدقائك وأصدقاء أصدقائك رؤية هذا المحتوى';
    }
  }
}

/// Simple dropdown privacy selector for compact UI
class PrivacyDropdown extends StatelessWidget {
  final PrivacyLevel selectedPrivacy;
  final Function(PrivacyLevel) onPrivacyChanged;

  const PrivacyDropdown({
    super.key,
    required this.selectedPrivacy,
    required this.onPrivacyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PrivacyLevel>(
          value: selectedPrivacy,
          isExpanded: true,
          dropdownColor: isDark ? Colors.grey[900] : Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDark ? Colors.white : Colors.black87,
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
          items: PrivacyLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Row(
                children: [
                  Icon(
                    _getPrivacyIcon(level),
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(level.arabicLabel),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onPrivacyChanged(value);
            }
          },
        ),
      ),
    );
  }

  IconData _getPrivacyIcon(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return Icons.public;
      case PrivacyLevel.friendsOnly:
        return Icons.group;
      case PrivacyLevel.friendsOfFriends:
        return Icons.people_outline;
    }
  }
}
