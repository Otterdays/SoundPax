import 'package:flutter/material.dart';

class AppTheme {
  // Darkest background for the main view
  static const Color background = Color(0xFF0D0D0D);
  // Pad surface colors
  static const Color surfaceBase = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color surfaceBright = Color(0xFF2B2B2B);

  // Neon highlights
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color secondaryPurple = Color(0xFFB388FF);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color activeGreen = Color(0xFF00E676);
  static const Color alertRed = Color(0xFFFF5252);

  // Text colors
  static const Color textBright = Color(0xFFF0F0F0);
  static const Color textMuted = Color(0xFF8E8E8E);
  static const Color textDim = Color(0xFF555555);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF121212),
        primary: primaryCyan,
        secondary: secondaryPurple,
        tertiary: accentPink,
        error: alertRed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textBright,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textBright,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textBright,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: textBright,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A0A),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textBright),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textBright,
        ),
      ),
    );
  }
}
