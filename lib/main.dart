import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/init/app_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env loaded");
  } catch (_) {
    debugPrint("⚠️ .env file not found - AI features may not work");
  }
  
  // Initialize FoodSaver services
  try {
    await initializeFoodSaver();
    debugPrint("✅ FoodSaver services initialized");
  } catch (e) {
    debugPrint("❌ FoodSaver init failed: $e");
  }
  
  runApp(const ProviderScope(child: FoodSaverApp()));
}

class FoodSaverApp extends StatelessWidget {
  const FoodSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FoodSaver',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
