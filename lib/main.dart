import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env is gitignored and holds your own GEMINI_API_KEY — it's fine if it's
    // missing (e.g. on a fresh checkout); the app still runs, the AI analysis
    // step will just report the key as missing instead of crashing at startup.
  }
  // Firebase.initializeApp() is safely omitted for this pure UI testing phase
  
  runApp(const FoodSaverApp());
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