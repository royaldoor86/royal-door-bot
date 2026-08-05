/// Privacy settings for stories and daily posts
enum PrivacyLevel {
  public, // للعامة - Everyone
  friendsOnly, // للأصدقاء فقط - Friends only
  friendsOfFriends, // أصدقاء الأصدقاء - Friends of friends
}

extension PrivacyLevelExtension on PrivacyLevel {
  String get arabicLabel {
    switch (this) {
      case PrivacyLevel.public:
        return 'للعامة';
      case PrivacyLevel.friendsOnly:
        return 'للأصدقاء فقط';
      case PrivacyLevel.friendsOfFriends:
        return 'أصدقاء الأصدقاء';
    }
  }

  String get englishLabel {
    switch (this) {
      case PrivacyLevel.public:
        return 'Public';
      case PrivacyLevel.friendsOnly:
        return 'Friends Only';
      case PrivacyLevel.friendsOfFriends:
        return 'Friends of Friends';
    }
  }

  String get value {
    switch (this) {
      case PrivacyLevel.public:
        return 'public';
      case PrivacyLevel.friendsOnly:
        return 'friends_only';
      case PrivacyLevel.friendsOfFriends:
        return 'friends_of_friends';
    }
  }

  static PrivacyLevel fromString(String value) {
    switch (value) {
      case 'public':
        return PrivacyLevel.public;
      case 'friends_only':
        return PrivacyLevel.friendsOnly;
      case 'friends_of_friends':
        return PrivacyLevel.friendsOfFriends;
      default:
        return PrivacyLevel.public;
    }
  }
}

/// Privacy settings for a user's content
class UserPrivacySettings {
  final String userId;
  final PrivacyLevel defaultStoryPrivacy;
  final PrivacyLevel defaultPostPrivacy;
  final bool allowStrangersToView;
  final bool hideFromStrangers;

  UserPrivacySettings({
    required this.userId,
    this.defaultStoryPrivacy = PrivacyLevel.public,
    this.defaultPostPrivacy = PrivacyLevel.public,
    this.allowStrangersToView = true,
    this.hideFromStrangers = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'defaultStoryPrivacy': defaultStoryPrivacy.value,
      'defaultPostPrivacy': defaultPostPrivacy.value,
      'allowStrangersToView': allowStrangersToView,
      'hideFromStrangers': hideFromStrangers,
    };
  }

  factory UserPrivacySettings.fromMap(Map<String, dynamic> data) {
    return UserPrivacySettings(
      userId: data['userId'] as String,
      defaultStoryPrivacy: PrivacyLevelExtension.fromString(
          data['defaultStoryPrivacy'] as String? ?? 'public'),
      defaultPostPrivacy: PrivacyLevelExtension.fromString(
          data['defaultPostPrivacy'] as String? ?? 'public'),
      allowStrangersToView: data['allowStrangersToView'] as bool? ?? true,
      hideFromStrangers: data['hideFromStrangers'] as bool? ?? false,
    );
  }
}
