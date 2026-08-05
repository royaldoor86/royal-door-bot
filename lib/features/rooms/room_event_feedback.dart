class RoomEventFeedback {
  static const String defaultAsset = 'sounds/notification.mp3';

  static String assetFor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'welcome':
        return 'sounds/royal.mp3';
      case 'battle':
        return 'sounds/crowd-cheer-406646.mp3';
      case 'gift':
        return 'sounds/gift.wav';
      default:
        return defaultAsset;
    }
  }
}
