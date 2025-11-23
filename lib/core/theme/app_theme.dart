import 'package:flutter/material.dart';

class AppTheme {
  // Dark theme colors
  static const Color primaryPurple = Color(0xFFAB7FFF);
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF222222);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF999999);
  static const Color accent = Color(0xFFFF6B9D);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: backgroundDark,
      
      // Set default font family to local Inter
      fontFamily: 'Inter',

      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: accent,
        background: backgroundDark,
        surface: surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: textSecondary,
        ),
      ),
      
      // Ensure standard text styles also use Inter
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Inter', color: textPrimary),
        displayMedium: TextStyle(fontFamily: 'Inter', color: textPrimary),
        displaySmall: TextStyle(fontFamily: 'Inter', color: textPrimary),
        headlineLarge: TextStyle(fontFamily: 'Inter', color: textPrimary),
        headlineMedium: TextStyle(fontFamily: 'Inter', color: textPrimary),
        headlineSmall: TextStyle(fontFamily: 'Inter', color: textPrimary),
        titleLarge: TextStyle(fontFamily: 'Inter', color: textPrimary),
        titleMedium: TextStyle(fontFamily: 'Inter', color: textPrimary),
        titleSmall: TextStyle(fontFamily: 'Inter', color: textPrimary),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: textPrimary),
        bodySmall: TextStyle(fontFamily: 'Inter', color: textSecondary),
        labelLarge: TextStyle(fontFamily: 'Inter', color: textPrimary),
        labelMedium: TextStyle(fontFamily: 'Inter', color: textPrimary),
        labelSmall: TextStyle(fontFamily: 'Inter', color: textSecondary),
      ),
    );
  }
}
