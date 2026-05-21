/// نموذج بيانات الدولة للتحقق من OTP
class CountryConfig {
  /// كود الدولة (ISO 3166-1 alpha-2)
  final String countryCode;

  /// اسم الدولة
  final String countryName;

  /// كود الاتصال الدولي (رمز الدول)
  final String dialCode;

  /// صيغة رقم الهاتف (Regex)
  final String phoneNumberFormat;

  /// طول رقم الهاتف المتوقع (بدون رمز الدول)
  final int? phoneNumberLength;

  /// نطاق طول رقم الهاتف (Min, Max)
  final (int, int)? phoneNumberLengthRange;

  /// قائمة مزودي الخدمة المدعومة
  final List<String> smsProviders;

  /// المزود الافتراضي
  final String defaultProvider;

  /// رمز العملة
  final String currencyCode;

  /// المنطقة الزمنية
  final String timezone;

  /// اللغات المدعومة
  final List<String> languages;

  /// تفاصيل إضافية
  final Map<String, dynamic>? metadata;

  CountryConfig({
    required this.countryCode,
    required this.countryName,
    required this.dialCode,
    required this.phoneNumberFormat,
    this.phoneNumberLength,
    this.phoneNumberLengthRange,
    required this.smsProviders,
    required this.defaultProvider,
    required this.currencyCode,
    required this.timezone,
    required this.languages,
    this.metadata,
  });

  /// الحصول على رقم الهاتف بالصيغة الدولية
  String formatPhoneNumber(String phoneNumber) {
    // إزالة كافة الرموز غير الرقمية (نحتفظ بـ + في البداية فقط مؤقتاً)
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // إذا بدأ الرقم بـ +964 مثلاً، نزيل الـ + لتوحيد الصيغة
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // إزالة كود الدولة إذا كان موجوداً بالفعل في بداية الرقم
    String dialCodeNoPlus = dialCode.replaceAll('+', '');
    if (cleaned.startsWith(dialCodeNoPlus)) {
      cleaned = cleaned.substring(dialCodeNoPlus.length);
    }

    // إزالة الصفر المحلي (مثل 0780)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // الآن نركب الرقم النهائي: كود الدولة + الرقم الصافي
    return dialCodeNoPlus + cleaned;
  }

  /// التحقق من صحة رقم الهاتف
  bool isValidPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // إزالة رمز الدول إن وجد
    if (cleaned.startsWith(dialCode)) {
      cleaned = cleaned.substring(dialCode.length);
    }

    // التحقق من الطول
    if (phoneNumberLengthRange != null) {
      final (min, max) = phoneNumberLengthRange!;
      if (cleaned.length < min || cleaned.length > max) {
        return false;
      }
    } else if (phoneNumberLength != null) {
      if (cleaned.length != phoneNumberLength) {
        return false;
      }
    } else {
      return false;
    }

    // التحقق من الصيغة
    try {
      final regex = RegExp(phoneNumberFormat);
      return regex.hasMatch(cleaned);
    } catch (e) {
      return false;
    }
  }

  /// الحصول على رقم الهاتف بدون رمز الدول
  static String removeDialCode(String phoneNumber, String dialCode) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith(dialCode)) {
      return cleaned.substring(dialCode.length);
    }
    if (cleaned.startsWith('0')) {
      return cleaned.substring(1);
    }
    return cleaned;
  }

  /// إخفاء معظم أرقام الهاتف
  String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 5) return phoneNumber;
    final lastDigits = phoneNumber.substring(phoneNumber.length - 4);
    final masked = '*' * (phoneNumber.length - 4);
    return '$masked$lastDigits';
  }

  factory CountryConfig.fromMap(Map<String, dynamic> map) {
    return CountryConfig(
      countryCode: map['countryCode'],
      countryName: map['countryName'],
      dialCode: map['dialCode'],
      phoneNumberFormat: map['phoneNumberFormat'],
      phoneNumberLength: map['phoneNumberLength'],
      phoneNumberLengthRange: map['phoneNumberLengthRange'] != null
          ? (map['phoneNumberLengthRange'][0], map['phoneNumberLengthRange'][1])
          : null,
      smsProviders: List<String>.from(map['smsProviders']),
      defaultProvider: map['defaultProvider'],
      currencyCode: map['currencyCode'],
      timezone: map['timezone'],
      languages: List<String>.from(map['languages']),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'dialCode': dialCode,
      'phoneNumberFormat': phoneNumberFormat,
      'phoneNumberLength': phoneNumberLength,
      'phoneNumberLengthRange': phoneNumberLengthRange != null
          ? [phoneNumberLengthRange!.$1, phoneNumberLengthRange!.$2]
          : null,
      'smsProviders': smsProviders,
      'defaultProvider': defaultProvider,
      'currencyCode': currencyCode,
      'timezone': timezone,
      'languages': languages,
      'metadata': metadata,
    };
  }
}
