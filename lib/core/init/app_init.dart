import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:foodsaver/core/services/notification_service.dart';
import 'package:foodsaver/firebase_options.dart';
import 'package:flutter/foundation.dart';

/// Initialize FoodSaver app services
Future<void> initializeFoodSaver() async {
  // 1. Initialize Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 2. Initialize App Check (debug mode for dev/testing)
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    debugPrint('✅ App Check initialized');
  } catch (e) {
    debugPrint('⚠️ App Check init failed: $e');
  }

  // 3. Disable reCAPTCHA app verification for testing
  try {
    await FirebaseAuth.instance
        .setSettings(appVerificationDisabledForTesting: true);
  } catch (e) {
    debugPrint('⚠️ App verification setting failed: $e');
  }

  // 4. Initialize notifications (FCM + local notifications channel)
  try {
    await NotificationService().initialize();
    debugPrint('✅ Notifications initialized');
  } catch (e) {
    debugPrint('⚠️ Notifications init failed: $e');
  }
}
