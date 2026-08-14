import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF10B981); // Emerald Green
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textLight),
      ),
    );
  }
}