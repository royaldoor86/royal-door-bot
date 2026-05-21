import 'package:flutter/material.dart';

class L10n {
  static final all = [
    const Locale('ar'),
    const Locale('en'),
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return 'العربية';
    }
  }
}

class Translations {
  final Locale locale;
  Translations(this.locale);

  static Translations of(BuildContext context) {
    return Translations(Localizations.localeOf(context));
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'app_title': 'رويال دور',
      'welcome_msg': 'عالم النخبة والمنافسة الملكية',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'royal_login': 'تسجيل الدخول الملكي',
      'social_login_google': 'الدخول بواسطة Google',
      'dont_have_account': 'ليس لديك حساب ملكي؟',
      'register_now': 'سجل الآن',
      'profile': 'بروفايل',
      'games': 'الألعاب',
      'chats': 'المحادثات',
      'rooms': 'الرومات',
      'diaries': 'اليوميات',
      'settings': 'الإعدادات',
      'about_app': 'حول التطبيق',
      'language': 'اللغة',
      'logout': 'تسجيل الخروج الملكي',
      'account_settings': 'إعدادات الحساب',
      'privacy': 'الخصوصية',
      'notifications': 'التنبيهات',
      'save': 'حفظ',
      'edit_profile': 'تعديل الملف الشخصي',
      'change_language': 'تغيير اللغة',
      'royal_membership': 'عضوية رويال الحصرية',
      'royal_privileges': 'امتيازات ملكية خاصة',
      'gems_title': 'جواهر ملكية',
      'coins_title': 'نجوم الشحن ⭐',
      'level': 'المستوى (XP)',
      'family': 'العائلة',
      'badges': 'الشارات',
      'my_appearance': 'مظهري',
      'daily_tasks': 'المهام اليومية',
      'daily_rewards': 'مكافأة تسجيل الدخول',
      'harvest': 'المكافآت الملكية',
      'harvest_market': 'سوق المكافآت',
      'vip_center': 'مركز VIP المطور',
      'royal_privileges_tab': 'امتيازات رويال',
      'vip_subscription': 'اشتراك VIP',
      'agent_panel': 'إدارة بيت الدعم',
      'agency_create': 'تأسيس بيت دعم ملكي',
      'friendly_points': 'نجوم الصداقة ⭐',
      'challenges': 'تحديات يومية',
      'invite_center': 'مركز الدعوات',
      'store': 'المتجر الملكي',
      'support': 'الدعم والمساعدة',
      'visitors': 'زوار البروفايل',
      'friends_list': 'قائمة الأصدقاء',
      'account_level': 'مستوى الحساب',
      'appearance_settings': 'إعدادات المظهر',
      'royal_notifications': 'الإشعارات الملكية',
      'privacy_and_security': 'الخصوصية والأمان',
    },
    'en': {
      'app_title': 'Royal Door',
      'welcome_msg': 'World of Elite and Royal Competition',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'royal_login': 'Royal Login',
      'social_login_google': 'Login with Google',
      'dont_have_account': "Don't have a Royal account?",
      'register_now': 'Register Now',
      'profile': 'Profile',
      'games': 'Games',
      'chats': 'Chats',
      'rooms': 'Rooms',
      'diaries': 'Diaries',
      'settings': 'Settings',
      'about_app': 'About App',
      'language': 'Language',
      'logout': 'Royal Logout',
      'account_settings': 'Account Settings',
      'privacy': 'Privacy',
      'notifications': 'Notifications',
      'save': 'Save',
      'edit_profile': 'Edit Profile',
      'change_language': 'Change Language',
      'royal_membership': 'Royal Exclusive Membership',
      'royal_privileges': 'Special Royal Privileges',
      'gems_title': 'Royal Gems',
      'coins_title': 'Recharge Stars ⭐',
      'level': 'Level (XP)',
      'family': 'Family',
      'badges': 'Badges',
      'my_appearance': 'My Appearance',
      'daily_tasks': 'Daily Tasks',
      'daily_rewards': 'Daily Login Rewards',
      'harvest': 'Royal Harvest',
      'harvest_market': 'Harvest Market',
      'global_market': 'Global Market',
      'vip_center': 'Advanced VIP Center',
      'royal_privileges_tab': 'Royal Privileges',
      'vip_subscription': 'VIP Subscription',
      'agent_panel': 'Support House Management',
      'agency_create': 'Establish Support House',
      'friendly_points': 'Friendly Stars ⭐',
      'challenges': 'Daily Challenges',
      'invite_center': 'Invite Center',
      'store': 'Royal Store',
      'support': 'Support & Help',
      'visitors': 'Profile Visitors',
      'friends_list': 'Friends List',
      'account_level': 'Account Level',
      'appearance_settings': 'Appearance Settings',
      'royal_notifications': 'Royal Notifications',
      'privacy_and_security': 'Privacy & Security',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}
