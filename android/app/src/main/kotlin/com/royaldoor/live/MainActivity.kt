package com.royaldoor.live

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    private val UNITY_CHANNEL = "com.royaldoor.unity"
    private var currentGemsBalance: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // تهيئة PlayerPrefs لـ Unity لضمان عمل Firebase في اللعبة
        try {
            val prefs = getSharedPreferences("${packageName}.v2.playerprefs", MODE_PRIVATE)
            prefs.edit().apply {
                putString("FirebaseDatabaseUrl", "https://royaldoor86-e6489-default-rtdb.firebaseio.com")
                apply()
            }
            android.util.Log.d("UnityBridge", "FirebaseDatabaseUrl set in PlayerPrefs")
        } catch (e: Exception) {
            android.util.Log.e("UnityBridge", "Error setting PlayerPrefs: ${e.message}")
        }

        // التواصل مع Unity
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UNITY_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setGemsBalance" -> {
                    val balance = call.argument<Int>("balance") ?: 0
                    val target = call.argument<String>("target") ?: "GameManager"
                    currentGemsBalance = balance
                    
                    // إرسال الرصيد إلى Unity
                    try {
                        val unityPlayerClass = Class.forName("com.unity3d.player.UnityPlayer")
                        val sendMessageMethod = unityPlayerClass.getMethod(
                            "UnitySendMessage",
                            String::class.java, String::class.java, String::class.java
                        )
                        sendMessageMethod.invoke(null, target, "SetGemsBalance", balance.toString())
                        android.util.Log.d("UnityChannel", "Gems balance sent to Unity object [$target]: $balance")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("UnityChannel", "Error sending to Unity object [$target]: ${e.message}")
                        result.success(false)
                    }
                }
                "requestAppBalance" -> {
                    // Unity تطلب الرصيد من التطبيق
                    result.success(currentGemsBalance)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        } catch (e: Exception) {
            // Plugin might not be registered, ignore error
        }
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
