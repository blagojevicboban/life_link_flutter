import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF000000);
  static const Color safe = Color(0xFF39FF14); // Neon Green
  static const Color warning = Color(0xFFFFAA00); // Bright Orange
  static const Color danger = Color(0xFFFF0000); // Alarm Red
  static const Color surface = Color(0xFF1A1A1A);
  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textDim = Color(0xFF888888);
  static const Color accent = Color(0xFF00E5FF); // Cyan Accent

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: safe,
      colorScheme: const ColorScheme.dark(
        primary: safe,
        secondary: warning,
        error: danger,
        surface: surface,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textMain, displayColor: textMain),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: safe,
          side: const BorderSide(color: safe, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
