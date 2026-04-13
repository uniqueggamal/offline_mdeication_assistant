import 'package:flutter/material.dart';

class AppTheme {
  // The exact "Warm/Coral" palette from your request
  static const Color background = Color(0xFFFFF0E6); // Very light peach/cream
  static const Color primary = Color(0xFFFF6B6B); // Soft Coral Red
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color text = Color(0xFF2D3436); // Dark Grey
  static const Color success = Color(0xFF00B894); // Mint Green
  static const Color error = Color(0xFFDC2626); // Health stock critical
  static const Color warning = Color(0xFFF97316); // Health stock low
  static const Color primaryLight = Color(0xFFFFEBE5); // Light coral tint
  static const Color textSecondary = Color(0xFF636E72);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        background: background,
        primary: primary,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: text,
      ),
      scaffoldBackgroundColor: background,

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: text,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      ),

      // Card Theme (Clean, white, rounded)
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0, // Flat design for cleaner look
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),

      // Input Decoration (For the Search Bar)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),

      // Floating Action Button (If used elsewhere)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
