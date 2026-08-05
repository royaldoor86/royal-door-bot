class RoomNotificationPreferences {
  const RoomNotificationPreferences({
    required this.enabled,
    required this.welcomeMessage,
    required this.toggles,
  });

  final bool enabled;
  final String welcomeMessage;
  final Map<String, bool> toggles;

  factory RoomNotificationPreferences.fromMap(Map<String, dynamic>? data) {
    final custom = data?['customNotifications'] as Map<String, dynamic>?;
    final toggles = (custom?['toggles'] as Map<String, dynamic>?) ?? {};

    return RoomNotificationPreferences(
      enabled: custom?['enabled'] ?? true,
      welcomeMessage:
          (custom?['welcomeMessage'] as String?)?.trim().isNotEmpty == true
              ? custom!['welcomeMessage'].trim()
              : '',
      toggles: {
        'welcome': toggles['welcome'] ?? true,
        'battle': toggles['battle'] ?? true,
        'gift': toggles['gift'] ?? true,
      },
    );
  }

  bool shouldShow(String eventType) {
    if (!enabled) return false;
    return toggles[eventType] ?? true;
  }

  String resolvedWelcomeMessage(String fallback) {
    if (welcomeMessage.isNotEmpty) return welcomeMessage;
    return fallback;
  }
}
