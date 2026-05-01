import 'package:flutter/material.dart';

/// ══════════════════════════════════════════════════════════════
/// AppTheme — Amour Dating App
/// Modern Passion Theme (Rose Red & Deep Violet)
/// ══════════════════════════════════════════════════════════════

class AppColors {
  // Brand Colors
  static const primary      = Color(0xFFE94057); // Rose Red
  static const secondary    = Color(0xFF8A2387); // Deep Purple
  static const accent       = Color(0xFFF27121); // Orange accent
  static const gold         = Color(0xFFD4AF37); // Metallic Gold
  static const primaryLight = Color(0xFFFFEBF0);

  // Gradients
  static const gradientPrimary  = [Color(0xFFE94057), Color(0xFFF27121)];
  static const gradientPremium  = [Color(0xFF8A2387), Color(0xFFE94057)];
  static const gradientLove     = [Color(0xFFFF0080), Color(0xFFFF8C00)];

  // Backgrounds
  static const lightBg      = Color(0xFFFFFFFF);
  static const lightCard    = Color(0xFFF8F8F8);
  static const lightText    = Color(0xFF121212);
  static const lightSubtext = Color(0xFF757575);

  static const darkBg       = Color(0xFF0F0F1A);
  static const darkCard     = Color(0xFF1A1A2E);
  static const darkText     = Color(0xFFFDFDFD);
  static const darkSubtext  = Color(0xFFADADAD);

  // Status
  static const success = Color(0xFF2ECC71);
  static const error   = Color(0xFFE74C3C);
  static const info    = Color(0xFF3498DB);
  static const online  = Color(0xFF2ECC71);
  static const offline = Color(0xFF9E9E9E);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightBg,
    ),
    scaffoldBackgroundColor: AppColors.lightBg,
    fontFamily: 'Nunito',
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.lightText,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.lightText),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 2,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(18),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      shadowColor: Colors.black12,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkBg,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.darkBg,
    fontFamily: 'Nunito',

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.darkText,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.darkText),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(18),
    ),
    
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
  );
}

class AppGradients {
  static const main = LinearGradient(
    colors: AppColors.gradientPrimary,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const premium = LinearGradient(
    colors: AppColors.gradientPremium,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration glass({double opacity = 0.1, double radius = 20}) => BoxDecoration(
    color: Colors.white.withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
  );
}
