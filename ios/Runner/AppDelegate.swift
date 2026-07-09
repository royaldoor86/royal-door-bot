import Flutter
import UIKit
import Firebase
import FirebaseAppCheck

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // إعداد Firebase App Check
    let appCheck = AppCheck.appCheck()
    
    // استخدام DebugProviderFactory للتطوير
    // للإنتاج، استخدم DeviceCheckProviderFactory أو AppAttestProviderFactory
    #if DEBUG
    appCheck.providerFactory = DebugAppCheckProviderFactory()
    #else
    appCheck.providerFactory = AppAttestProviderFactory()
    #endif
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
