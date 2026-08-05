import 'package:teledart/teledart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class TelegramBotService {
  static final TelegramBotService _instance = TelegramBotService._internal();
  static TelegramBotService get instance => _instance;
  factory TelegramBotService() => _instance;
  TelegramBotService._internal();

  TeleDart? _teledart;
  bool _initialized = false;
  String? _botToken;
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _botToken = dotenv.env['TELEGRAM_BOT_TOKEN'];
      if (_botToken == null || _botToken!.isEmpty) {
        print('⚠️ TelegramBotService: TELEGRAM_BOT_TOKEN not found in .env');
        return;
      }

      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;

      _teledart = TeleDart(_botToken!, Event(''));
      
      // We no longer call _teledart!.start() here because the bot is now handled
      // by Firebase Cloud Functions to ensure 24/7 availability.
      // This service in the app is now used only for sending messages/photos.

      _initialized = true;

      // Monitor connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
        final nowOnline = result != ConnectivityResult.none;
        // Logic for start/stop removed as it's now server-side
        _isOnline = nowOnline;
      });

      print('✅ TelegramBotService: Bot initialized successfully');
    } catch (e) {
      print('❌ TelegramBotService: Initialization failed - $e');
    }
  }

  bool get isInitialized => _initialized;
  TeleDart? get teledart => _teledart;

  Future<void> sendMessage(String chatId, String text) async {
    if (!_initialized || _teledart == null) {
      print('⚠️ TelegramBotService: Bot not initialized');
      return;
    }

    if (!_isOnline) {
      print('⚠️ TelegramBotService: No internet connection, cannot send message');
      return;
    }

    try {
      await _teledart!.sendMessage(chatId, text);
      print('✅ TelegramBotService: Message sent to $chatId');
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Software caused connection abort')) {
        print('🌐 TelegramBotService: Network error while sending message, likely offline');
      } else {
        print('❌ TelegramBotService: Failed to send message - $e');
      }
    }
  }

  Future<void> sendPhoto(String chatId, String photoUrl, {String? caption}) async {
    if (!_initialized || _teledart == null) {
      print('⚠️ TelegramBotService: Bot not initialized');
      return;
    }

    if (!_isOnline) {
      print('⚠️ TelegramBotService: No internet connection, cannot send photo');
      return;
    }

    try {
      await _teledart!.sendPhoto(chatId, photoUrl, caption: caption);
      print('✅ TelegramBotService: Photo sent to $chatId');
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Software caused connection abort')) {
        print('🌐 TelegramBotService: Network error while sending photo');
      } else {
        print('❌ TelegramBotService: Failed to send photo - $e');
      }
    }
  }

  void dispose() {
    _teledart?.stop();
    _connectivitySubscription?.cancel();
    _initialized = false;
  }
}
