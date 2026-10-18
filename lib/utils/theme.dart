import 'package:flutter/material.dart';

/// App Theme & Design System for Ironote
/// Inspired by the Emerald Neon Fintech Glassmorphism Design
class AppTheme {
  // Emerald Neon Palette (Exact match to reference screenshots)
  static const Color neonGreen = Color(0xFF00E599); // Electric Emerald
  static const Color neonGreenDark = Color(0xFF059669);
  static const Color accentMint = Color(0xFF10B981);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color danger = Color(0xFFF43F5E); // Rose
  static const Color warning = Color(0xFFF59E0B); // Amber

  // Aliases for compatibility
  static const Color primary = neonGreen;
  static const Color primaryDark = neonGreenDark;
  static const Color success = neonGreen;
  static const Color info = accentCyan;

  // Dark Theme Colors (Deep Obsidian / Forest OLED)
  static const Color darkBg = Color(0xFF0B1315);
  static const Color darkBgSecondary = Color(0xFF070D0E);
  static const Color darkCard = Color(0xFF111E22);
  static const Color darkCardHover = Color(0xFF16272C);
  static const Color darkInput = Color(0xFF0D171A);
  static const Color darkBorder = Color(0xFF1E3339);
  static const Color darkTextMain = Color(0xFFF8FAFC);
  static const Color darkTextSub = Color(0xFF7E9DA4);

  // Light Theme Colors (Mint Pearl / Clean White)
  static const Color lightBg = Color(0xFFF0FDF4);
  static const Color lightBgSecondary = Color(0xFFE6F7F0);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF8FAFC);
  static const Color lightInput = Color(0xFFF0FDF4);
  static const Color lightBorder = Color(0xFFD1FAE5);
  static const Color lightTextMain = Color(0xFF064E3B);
  static const Color lightTextSub = Color(0xFF059669);

  // Gradients
  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF00E599), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF132328), Color(0xFF0B1518)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBannerGradient = LinearGradient(
    colors: [Color(0xFF00E599), Color(0xFF047857), Color(0xFF064E3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: accentMint,
        surface: darkCard,
        error: danger,
        onPrimary: Color(0xFF042F2E),
        onSurface: darkTextMain,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextMain,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: darkTextMain),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInput,
        hintStyle: const TextStyle(color: darkTextSub, fontSize: 14),
        labelStyle: const TextStyle(color: darkTextSub, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: neonGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: neonGreenDark,
      colorScheme: const ColorScheme.light(
        primary: neonGreenDark,
        secondary: accentMint,
        surface: lightCard,
        error: danger,
        onPrimary: Colors.white,
        onSurface: lightTextMain,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextMain,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: lightTextMain),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shadowColor: neonGreen.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInput,
        hintStyle: const TextStyle(color: lightTextSub, fontSize: 14),
        labelStyle: const TextStyle(color: lightTextSub, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: neonGreenDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
      ),
    );
  }
}
