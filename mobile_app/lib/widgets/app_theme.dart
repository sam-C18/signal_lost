import 'package:flutter/material.dart';

/// Centralized design tokens for SignalLost.
/// Update here to propagate changes across the entire app.
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ──────────────────────────────────────────────────────────
  static const Color sosRed = Color(0xFFFF3B30);
  static const Color sosRedDim = Color(0xFF7A1A15);
  static const Color backgroundDark = Color(0xFF0A0A0C);
  static const Color surfaceDark = Color(0xFF141418);
  static const Color surfaceCard = Color(0xFF1C1C22);
  static const Color borderColor = Color(0xFF2A2A32);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E9A);
  static const Color textMuted = Color(0xFF4A4A56);
  static const Color successGreen = Color(0xFF30D158);
  static const Color wifiBlue = Color(0xFF0A84FF);    // Wi-Fi Direct indicator
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color disabledGrey = Color(0xFF3A3A42);

  // ─── Typography ────────────────────────────────────────────────────────────
  static const String fontFamily = 'Courier'; // Monospace = tactical feel

  // ─── Theme Data ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: sosRed,
        surface: surfaceDark,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 4,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: 8,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: textMuted,
          fontSize: 11,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
