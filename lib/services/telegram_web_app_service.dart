// lib/services/telegram_web_app_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelegramWebAppService {
  static Map<String, dynamic>? _initData;
  static bool _isInitialized = false;
  static const String _storageKey = 'telegram_init_data';

  /// تهيئة Telegram Web App
  static Future<void> init() async {
    if (_isInitialized) return;
    
    if (kIsWeb) {
      try {
        // Check if running in Telegram Web App
        final isTelegram = _isTelegramWebApp();
        debugPrint('🚀 Telegram Web App init - isTelegram: $isTelegram');
        
        if (isTelegram) {
          // Wait for Telegram WebApp SDK to be ready
          await _waitForTelegramSDK();
          
          // Try multiple methods to get init data with retries
          for (int i = 0; i < 3; i++) {
            debugPrint('🔄 Attempt ${i + 1} to get Telegram data...');
            
            // Try to get init data from URL
            _initData = _parseInitDataFromUrl();
            if (_initData != null) {
              debugPrint('✅ Telegram Web App initialized with URL data: $_initData');
              await _saveInitData(_initData!); // Save to storage
              break;
            }
            
            // Also try to get data from window.Telegram.WebApp if available
            _initData = _initData ?? _parseInitDataFromWindow();
            if (_initData != null) {
              debugPrint('✅ Telegram Web App data from window: $_initData');
              await _saveInitData(_initData!); // Save to storage
              break;
            }
            
            // Try to get data from the HTML-stored object
            _initData = _initData ?? _parseInitDataFromWindowObject();
            if (_initData != null) {
              debugPrint('✅ Telegram Web App data from window object: $_initData');
              await _saveInitData(_initData!); // Save to storage
              break;
            }
            
            // Wait before retry
            if (i < 2) {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
          
          if (_initData == null) {
            debugPrint('⚠️ Failed to get Telegram data after retries');
            // Try to load from storage as fallback
            _initData = await _loadInitData();
            if (_initData != null) {
              debugPrint('✅ Loaded Telegram data from storage: $_initData');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error initializing Telegram Web App: $e');
      }
    }
    _isInitialized = true;
  }

  /// Save init data to SharedPreferences
  static Future<void> _saveInitData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(_storageKey, jsonString);
      debugPrint('💾 Telegram data saved to storage');
    } catch (e) {
      debugPrint('❌ Error saving Telegram data to storage: $e');
    }
  }

  /// Load init data from SharedPreferences
  static Future<Map<String, dynamic>?> _loadInitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint('📂 Telegram data loaded from storage');
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error loading Telegram data from storage: $e');
      return null;
    }
  }

  /// Clear saved init data from SharedPreferences
  static Future<void> _clearInitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      debugPrint('🗑️ Telegram data cleared from storage');
    } catch (e) {
      debugPrint('❌ Error clearing Telegram data from storage: $e');
    }
  }

  /// Wait for Telegram WebApp SDK to be ready
  static Future<void> _waitForTelegramSDK() async {
    for (int i = 0; i < 10; i++) {
      try {
        // Check if Telegram WebApp is available and ready
        final isReady = await _isTelegramSDKReady();
        if (isReady) {
          debugPrint('✅ Telegram WebApp SDK is ready');
          return;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('⚠️ Error checking Telegram SDK readiness: $e');
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    debugPrint('⚠️ Telegram WebApp SDK did not become ready after retries');
  }

  /// Check if Telegram WebApp SDK is ready
  static Future<bool> _isTelegramSDKReady() async {
    try {
      // This would use JS interop to check window.Telegram.WebApp
      // For now, we'll assume it's ready if we're in Telegram environment
      return _isTelegramWebApp();
    } catch (e) {
      return false;
    }
  }

  /// التحقق مما إذا كان التطبيق يعمل داخل Telegram
  static bool _isTelegramWebApp() {
    if (!kIsWeb) return false;
    try {
      // Check for Telegram Mini App indicators in URL
      final uri = Uri.base;
      debugPrint('🔍 Checking if Telegram Mini App: $uri');
      debugPrint('🔍 User Agent: ${_getUserAgent()}');
      
      final hasTgData = uri.queryParameters.containsKey('tgWebAppData') || 
                       uri.fragment.contains('tgWebAppData');
      final hasTelegramParams = uri.queryParameters.containsKey('user') ||
                               uri.queryParameters.containsKey('query_id');
      
      // Check if Telegram WebApp is available via JS interop
      final hasTelegramInWindow = _hasTelegramWebAppInWindow();
      
      final isTelegram = hasTgData || hasTelegramParams || hasTelegramInWindow;
      debugPrint('🔍 Telegram Mini App detection: hasTgData=$hasTgData, hasTelegramParams=$hasTelegramParams, hasTelegramInWindow=$hasTelegramInWindow, isTelegram=$isTelegram');
      
      return isTelegram;
    } catch (e) {
      debugPrint('❌ Error checking Telegram Mini App: $e');
      return false;
    }
  }

  /// Get user agent for debugging
  static String _getUserAgent() {
    try {
      // This would use JS interop to get navigator.userAgent
      // For now, return a placeholder
      return 'Unknown';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Check if Telegram WebApp is available in window
  static bool _hasTelegramWebAppInWindow() {
    try {
      // Check if Telegram WebApp SDK is loaded and has initData
      // This uses the data stored by the HTML initialization script
      return false; // Will be checked via JS interop in init()
    } catch (e) {
      return false;
    }
  }

  /// تحليل بيانات init من URL
  static Map<String, dynamic>? _parseInitDataFromUrl() {
    try {
      final uri = Uri.base;
      final params = uri.queryParameters;
      
      debugPrint('🔍🔍🔍 Parsing Telegram data from URL');
      debugPrint('🔍 Full URL: $uri');
      debugPrint('🔍 URL params: $params');
      debugPrint('🔍 URL fragment: ${uri.fragment}');
      debugPrint('🔍 Params count: ${params.length}');
      debugPrint('🔍 Fragment length: ${uri.fragment.length}');
      
      if (params.isEmpty && uri.fragment.isEmpty) {
        debugPrint('❌❌❌ No URL params or fragment found - This is the problem!');
        debugPrint('❌❌❌ URL does not contain Telegram data');
        debugPrint('❌❌❌ This means BotFather is not sending Telegram data in the URL');
        return null;
      }
      
      final Map<String, dynamic> data = {};
      
      // Parse user data if present
      if (params.containsKey('user')) {
        try {
          final userJson = Uri.decodeComponent(params['user']!);
          debugPrint('🔍 User JSON: $userJson');
          data['user'] = jsonDecode(userJson);
          debugPrint('✅ Successfully parsed user from URL params');
        } catch (e) {
          debugPrint('❌ Error parsing user JSON: $e');
        }
      }
      
      // Try to get from fragment (hash) as well
      if (data['user'] == null && uri.fragment.isNotEmpty) {
        debugPrint('📝 Trying to parse from fragment: ${uri.fragment}');
        try {
          final fragmentParams = Uri.splitQueryString(uri.fragment);
          debugPrint('📝 Fragment params: $fragmentParams');
          
          final fragmentUser = fragmentParams['user'];
          if (fragmentUser != null) {
            final decodedUser = Uri.decodeComponent(fragmentUser);
            debugPrint('📝 Fragment decoded user: $decodedUser');
            final userJson = jsonDecode(decodedUser);
            data['user'] = userJson;
            debugPrint('✅ Successfully parsed user from fragment');
          }
        } catch (e) {
          debugPrint('❌ Error parsing fragment: $e');
        }
      }
      
      // Try to get tgWebAppData parameter
      if (data['user'] == null) {
        final tgWebAppData = params['tgWebAppData'];
        if (tgWebAppData != null) {
          debugPrint('📝 Found tgWebAppData parameter');
          try {
            final decodedData = Uri.decodeComponent(tgWebAppData);
            debugPrint('📝 Decoded tgWebAppData: $decodedData');
            final dataParams = Uri.splitQueryString(decodedData);
            debugPrint('📝 tgWebAppData params: $dataParams');
            
            final userFromTgData = dataParams['user'];
            if (userFromTgData != null) {
              final userJson = jsonDecode(userFromTgData);
              data['user'] = userJson;
              debugPrint('✅ Successfully parsed user from tgWebAppData');
            }
          } catch (e) {
            debugPrint('❌ Error parsing tgWebAppData: $e');
          }
        }
      }
      
      data['query_id'] = params['query_id'];
      data['auth_date'] = params['auth_date'];
      data['hash'] = params['hash'];
      
      debugPrint('✅ Parsed Telegram data: $data');
      if (data['user'] != null) {
        debugPrint('✅ User ID found: ${data['user']['id']}');
      } else {
        debugPrint('❌❌❌ No user data found in any parameter');
      }
      return data;
    } catch (e) {
      debugPrint('❌ Error parsing init data from URL: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// تحليل بيانات init من window.Telegram.WebApp
  static Map<String, dynamic>? _parseInitDataFromWindow() {
    try {
      // For now, use a simpler approach without complex JS interop
      // This will be implemented properly when JS interop is stabilized
      debugPrint('Window-based Telegram data parsing - using simplified approach');
      return null;
    } catch (e) {
      debugPrint('❌ Error parsing init data from window: $e');
      return null;
    }
  }

  /// تحليل بيانات init من window object (stored by HTML script)
  static Map<String, dynamic>? _parseInitDataFromWindowObject() {
    // JS interop removed - Telegram login disabled
    return null;
  }

  /// الحصول على بيانات المستخدم من Telegram
  static Map<String, dynamic>? getTelegramUserData() {
    return _initData?['user'];
  }

  /// الحصول على معرف المستخدم من Telegram
  static String? getTelegramUserId() {
    return _initData?['user']?['id']?.toString();
  }

  /// الحصول على اسم المستخدم من Telegram
  static String? getTelegramUserName() {
    return _initData?['user']?['username'];
  }

  /// الحصول على الاسم الأول من Telegram
  static String? getTelegramFirstName() {
    return _initData?['user']?['first_name'];
  }

  /// الحصول على الاسم الأخير من Telegram
  static String? getTelegramLastName() {
    return _initData?['user']?['last_name'];
  }

  /// الحصول على لغة المستخدم من Telegram
  static String? getTelegramLanguage() {
    return _initData?['user']?['language_code'];
  }

  /// التحقق مما إذا كان التطبيق يعمل داخل Telegram
  static bool isTelegramWebApp() {
    return kIsWeb && _initData != null;
  }

  /// مشاركة نص في Telegram
  static void shareText(String text) {
    final url = 'https://t.me/share/url?url=&text=${Uri.encodeComponent(text)}';
    // Only works in web builds
    if (kIsWeb) {
      // For web, we would use dart:js here, but disabled for now
      // Can be implemented with web-specific packages
    }
  }

  /// مشاركة رابط الغرفة في Telegram
  static void shareRoomInvite(String roomId, String roomName) {
    final text = '🎤 انضم إلى الغرفة الصوتية: $roomName\n🔗 https://royaldoor86-e6489.web.app/room/$roomId';
    shareText(text);
  }

  /// مشاركة دعوة صديق في Telegram
  static void shareFriendInvite(String referralCode) {
    final text = '👑 انضم إلى Royal Door واستمتع بالخدمات الملكية!\n🎁 استخدم كود الدعوة: $referralCode\n🔗 https://royaldoor86-e6489.web.app';
    shareText(text);
  }

  /// تسجيل الدخول عبر Telegram Web App باستخدام Custom Token
  static Future<String?> loginWithTelegram() async {
    try {
      debugPrint('🚀🚀🚀 loginWithTelegram START');
      debugPrint('🔍 Platform: ${kIsWeb ? "Web" : "Mobile"}');
      debugPrint('🔍 Current URL: ${Uri.base}');
      
      // Re-initialize to ensure we have the latest data
      debugPrint('🔄 Re-initializing Telegram Web App...');
      await init();
      debugPrint('✅ Telegram Web App initialization completed');
      
      // If still no data after init, try loading from storage directly
      if (_initData == null) {
        debugPrint('⚠️ No init data after init, trying storage...');
        _initData = await _loadInitData();
        if (_initData != null) {
          debugPrint('✅ Loaded Telegram data from storage in login');
        }
      }
      
      final telegramUserId = getTelegramUserId();
      debugPrint('📝📝📝 Telegram User ID: $telegramUserId');
      debugPrint('📝 First Name: ${getTelegramFirstName()}');
      debugPrint('📝 Last Name: ${getTelegramLastName()}');
      debugPrint('📝 Username: ${getTelegramUserName()}');
      debugPrint('📝 Init data: $_initData');
      
      if (telegramUserId == null) {
        debugPrint('❌❌❌ Failed to get Telegram User ID from initialized data');
        
        // Try to get from URL parameters as fallback
        final uri = Uri.base;
        final userIdFromUrl = uri.queryParameters['user'];
        debugPrint('📝 User ID from URL params: $userIdFromUrl');
        debugPrint('📝 All URL params: ${uri.queryParameters}');
        debugPrint('📝 URL fragment: ${uri.fragment}');
        
        if (userIdFromUrl != null) {
          try {
            debugPrint('⏳ Attempting to parse user JSON from URL...');
            final userJson = Uri.decodeComponent(userIdFromUrl);
            debugPrint('📝 Decoded user JSON: $userJson');
            final userData = jsonDecode(userJson);
            final parsedUserId = userData['id']?.toString();
            debugPrint('📝📝📝 Parsed User ID from JSON: $parsedUserId');
            debugPrint('📝 Parsed first_name: ${userData['first_name']}');
            debugPrint('📝 Parsed last_name: ${userData['last_name']}');
            debugPrint('📝 Parsed username: ${userData['username']}');
            
            if (parsedUserId != null) {
              debugPrint('✅ Using parsed user data from URL');
              // Save this data to storage for future use
              await _saveInitData({'user': userData});
              return _loginWithTelegramId(parsedUserId, userData['first_name'], userData['last_name'], userData['username']);
            }
          } catch (e) {
            debugPrint('❌❌❌ Error parsing user JSON: $e');
            debugPrint('❌ Error type: ${e.runtimeType}');
          }
        }
        
        // If still no user data, show detailed error
        debugPrint('❌❌❌ Full URL: $uri');
        debugPrint('❌❌❌ Query params: ${uri.queryParameters}');
        debugPrint('❌❌❌ Fragment: ${uri.fragment}');
        debugPrint('❌❌❌ Init data: $_initData');
        debugPrint('❌❌❌ Is Telegram Web App: ${isTelegramWebApp()}');
        
        return 'فشل الحصول على معرف Telegram. يرجى التأكد من أن التطبيق مفتوح من خلال بوت Telegram.\n\nإذا كنت تفتح من البوت، يرجى:\n1. مسح cache Telegram\n2. إعادة فتح التطبيق من البوت\n3. التأكد من إعدادات BotFather\n\nمعلومات التصحيح:\nURL: $uri';
      }

      debugPrint('✅✅✅ Using Telegram User ID: $telegramUserId');
      return _loginWithTelegramId(telegramUserId, getTelegramFirstName(), getTelegramLastName(), getTelegramUserName());
    } catch (e) {
      debugPrint('❌❌❌ Telegram Login Error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Error stack trace: ${StackTrace.current}');
      return 'خطأ غير متوقع: $e';
    }
  }

  /// Helper method to login with Telegram ID
  static Future<String?> _loginWithTelegramId(String telegramId, String? firstName, String? lastName, String? username) async {
    try {
      debugPrint('📞 Calling Cloud Function getTelegramCustomToken with ID: $telegramId');
      // Call Cloud Function to get custom token
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('getTelegramCustomToken').call({
        'telegram_id': telegramId,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'username': username ?? '',
      });

      debugPrint('📝 Cloud Function result: $result');
      
      final customToken = result.data['token'];
      if (customToken == null) {
        debugPrint('❌ Custom token is null');
        return 'فشل الحصول على رمز المصادقة من الخادم.';
      }

      debugPrint('🔑 Signing in with custom token...');
      // Sign in with custom token
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      debugPrint('✅ Telegram login successful');
      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Telegram Login Error (Functions): ${e.code} - ${e.message}');
      return 'خطأ في الاتصال بالخادم: ${e.message}';
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      return 'خطأ في المصادقة: ${e.message}';
    } catch (e) {
      debugPrint('❌ Telegram Login Error: $e');
      return 'خطأ غير متوقع: $e';
    }
  }
}
