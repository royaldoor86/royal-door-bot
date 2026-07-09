/// أكواد الأخطاء الخاصة بنظام OTP
class OTPErrorCode {
  // أخطاء المصادقة
  static const String unauthenticated = 'unauthenticated';
  static const String invalidCredentials = 'invalid_credentials';

  // أخطاء رقم الهاتف
  static const String invalidPhoneFormat = 'invalid_phone_format';
  static const String invalidPhoneLength = 'invalid_phone_length';
  static const String unsupportedCountry = 'unsupported_country';
  static const String invalidCountryCode = 'invalid_country_code';
  static const String phoneNumberBlocked = 'phone_number_blocked';

  // أخطاء OTP
  static const String invalidOTPFormat = 'invalid_otp_format';
  static const String invalidOTPLength = 'invalid_otp_length';
  static const String invalidOTP = 'invalid_otp';
  static const String otpExpired = 'otp_expired';
  static const String otpNotSent = 'otp_not_sent';
  static const String maxAttemptsExceeded = 'max_attempts_exceeded';
  static const String tooManyRequests = 'too_many_requests';

  // أخطاء المزودين
  static const String providerError = 'provider_error';
  static const String providerTimeout = 'provider_timeout';
  static const String providerUnavailable = 'provider_unavailable';
  static const String allProvidersUnavailable = 'all_providers_unavailable';

  // أخطاء النظام
  static const String networkError = 'network_error';
  static const String serverError = 'server_error';
  static const String unknownError = 'unknown_error';
  static const String timeoutError = 'timeout_error';
  static const String rateLimitExceeded = 'rate_limit_exceeded';

  // أخطاء الجلسة
  static const String sessionExpired = 'session_expired';
  static const String sessionNotFound = 'session_not_found';
  static const String invalidSession = 'invalid_session';
}

/// رسائل الأخطاء متعددة اللغات
class OTPErrorMessages {
  static final Map<String, Map<String, String>> _messages = {
    OTPErrorCode.unauthenticated: {
      'ar': 'يجب تسجيل الدخول أولاً',
      'en': 'Please log in first',
    },
    OTPErrorCode.invalidCredentials: {
      'ar': 'بيانات دخول غير صحيحة',
      'en': 'Invalid credentials',
    },
    OTPErrorCode.invalidPhoneFormat: {
      'ar': 'صيغة رقم الهاتف غير صحيحة',
      'en': 'Invalid phone number format',
    },
    OTPErrorCode.invalidPhoneLength: {
      'ar': 'طول رقم الهاتف غير صحيح',
      'en': 'Invalid phone number length',
    },
    OTPErrorCode.unsupportedCountry: {
      'ar': 'الدولة المحددة غير مدعومة حالياً',
      'en': 'Selected country is not supported',
    },
    OTPErrorCode.invalidCountryCode: {
      'ar': 'كود الدولة غير صحيح',
      'en': 'Invalid country code',
    },
    OTPErrorCode.phoneNumberBlocked: {
      'ar': 'رقم الهاتف محظور. يرجى التواصل مع الدعم',
      'en': 'Phone number is blocked. Please contact support',
    },
    OTPErrorCode.invalidOTPFormat: {
      'ar': 'صيغة الرمز غير صحيحة. يجب أن يكون 6 أرقام',
      'en': 'Invalid OTP format. Must be 6 digits',
    },
    OTPErrorCode.invalidOTPLength: {
      'ar': 'طول الرمز غير صحيح',
      'en': 'Invalid OTP length',
    },
    OTPErrorCode.invalidOTP: {
      'ar': 'الرمز غير صحيح. حاول مرة أخرى',
      'en': 'Incorrect OTP. Please try again',
    },
    OTPErrorCode.otpExpired: {
      'ar': 'انتهت صلاحية الرمز. يرجى طلب رمز جديد',
      'en': 'OTP has expired. Please request a new one',
    },
    OTPErrorCode.otpNotSent: {
      'ar': 'فشل في إرسال الرمز. حاول مرة أخرى',
      'en': 'Failed to send OTP. Please try again',
    },
    OTPErrorCode.maxAttemptsExceeded: {
      'ar': 'تجاوزت عدد محاولات التحقق. أعد المحاولة لاحقاً',
      'en': 'Too many verification attempts. Try again later',
    },
    OTPErrorCode.tooManyRequests: {
      'ar': 'لقد أرسلت طلبات كثيرة. انتظر قليلاً وحاول مرة أخرى',
      'en': 'Too many requests. Please wait and try again',
    },
    OTPErrorCode.providerError: {
      'ar': 'خطأ من المزود. يرجى المحاولة لاحقاً',
      'en': 'Provider error. Please try later',
    },
    OTPErrorCode.providerTimeout: {
      'ar': 'انتهت مهلة الانتظار. حاول مرة أخرى',
      'en': 'Request timeout. Please try again',
    },
    OTPErrorCode.providerUnavailable: {
      'ar': 'الخدمة غير متاحة حالياً',
      'en': 'Service is currently unavailable',
    },
    OTPErrorCode.allProvidersUnavailable: {
      'ar': 'جميع المزودين غير متاحين حالياً',
      'en': 'All providers are currently unavailable',
    },
    OTPErrorCode.networkError: {
      'ar': 'خطأ في الاتصال. تحقق من اتصالك بالإنترنت',
      'en': 'Network error. Check your internet connection',
    },
    OTPErrorCode.serverError: {
      'ar': 'خطأ في الخادم. حاول مرة أخرى',
      'en': 'Server error. Please try again',
    },
    OTPErrorCode.unknownError: {
      'ar': 'حدث خطأ غير معروف',
      'en': 'An unknown error occurred',
    },
    OTPErrorCode.timeoutError: {
      'ar': 'انتهت مهلة الانتظار',
      'en': 'Request timeout',
    },
    OTPErrorCode.rateLimitExceeded: {
      'ar': 'تم تجاوز حد الطلبات. حاول لاحقاً',
      'en': 'Rate limit exceeded. Try again later',
    },
    OTPErrorCode.sessionExpired: {
      'ar': 'انتهت صلاحية الجلسة',
      'en': 'Session has expired',
    },
    OTPErrorCode.sessionNotFound: {
      'ar': 'لم يتم العثور على الجلسة',
      'en': 'Session not found',
    },
    OTPErrorCode.invalidSession: {
      'ar': 'جلسة غير صحيحة',
      'en': 'Invalid session',
    },
  };

  /// الحصول على رسالة الخطأ
  static String getMessage(
    String errorCode, {
    String language = 'ar',
    String? countryName,
  }) {
    final message = _messages[errorCode]?[language] ??
        _messages[errorCode]?['en'] ??
        'خطأ غير معروف';

    // إضافة اسم الدولة إذا كان متوفراً
    if (countryName != null) {
      if (errorCode == OTPErrorCode.unsupportedCountry) {
        return '$message: $countryName';
      }
    }

    return message;
  }

  /// الحصول على رسالة الخطأ مع السياق
  static String getMessageWithContext(
    String errorCode, {
    String language = 'ar',
    String? countryName,
    int? attemptsRemaining,
    int? timeRemaining,
  }) {
    var message = getMessage(errorCode, language: language);

    if (attemptsRemaining != null) {
      final attemptsText = language == 'ar'
          ? 'المحاولات المتبقية: $attemptsRemaining'
          : 'Attempts remaining: $attemptsRemaining';
      message = '$message\n$attemptsText';
    }

    if (timeRemaining != null) {
      final minutes = timeRemaining ~/ 60;
      final seconds = timeRemaining % 60;
      final timeText = language == 'ar'
          ? 'أعد المحاولة بعد $minutes:${seconds.toString().padLeft(2, '0')}'
          : 'Try again in $minutes:${seconds.toString().padLeft(2, '0')}';
      message = '$message\n$timeText';
    }

    return message;
  }

  /// الحصول على جميع الرسائل لكود معين
  static Map<String, String>? getMessagesByCode(String errorCode) {
    return _messages[errorCode];
  }
}
