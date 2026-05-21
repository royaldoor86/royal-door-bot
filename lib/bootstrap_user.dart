import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_bootstrap_service.dart';
import 'services/fcm_service.dart';

Future<void> bootstrapUserIfNeeded() async {
  if (FirebaseAuth.instance.currentUser != null) {
    await UserBootstrapService.bootstrapUser();
    await FcmService.registerTokenForCurrentUser();
  }
}
