import 'package:flutter/material.dart';

/// ══════════════════════════════════════════════════════════════
/// AppTheme — Amour Dating App
/// Pink/Purple Romantic Gradient Theme
/// ══════════════════════════════════════════════════════════════

class AppColors {
  static const primary      = Color(0xFFFF4B6E);
  static const primaryLight = Color(0xFFFF8E9B);
  static const secondary    = Color(0xFF9B59B6);
  static const accent       = Color(0xFFFF6B35);
  static const gold         = Color(0xFFFFD700);

  static const gradientPink     = [Color(0xFFFF4B6E), Color(0xFFFF8E9B)];
  static const gradientPurple   = [Color(0xFF9B59B6), Color(0xFF6C3483)];
  static const gradientRomantic = [Color(0xFFFF4B6E), Color(0xFF9B59B6)];
  static const gradientSunset   = [Color(0xFFFF6B35), Color(0xFFFF4B6E)];
  static const gradientGold     = [Color(0xFFFFD700), Color(0xFFFFA500)];
  static const gradientDark     = [Color(0xFF1A1A1A), Color(0xFF000000)];

  static const lightBg      = Color(0xFFFFF8F9);
  static const lightCard    = Color(0xFFFFFFFF);
  static const lightText    = Color(0xFF1A1A1A);
  static const lightSubtext = Color(0xFF666666);
  static const lightBorder  = Color(0xFFEEEEEE);
  static const lightDivider = Color(0xFFF0F0F0);

  static const darkBg       = Color(0xFF0F0F1A);
  static const darkCard     = Color(0xFF1A1A2E);
  static const darkText     = Color(0xFFF0F0F0);
  static const darkSubtext  = Color(0xFF999999);

  static const success = Color(0xFF4CAF50);
  static const error   = Color(0xFFF44336);
  static const warning = Color(0xFFFF9800);
  static const info    = Color(0xFF2196F3);
  static const online  = Color(0xFF4CAF50);
  static const offline = Color(0xFF9E9E9E);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightCard,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.lightBg,
    fontFamily: 'Nunito',

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.lightText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamily: 'Nunito',
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF0F0F0),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.darkBg,
    fontFamily: 'Nunito',
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData get light => lightTheme;
}

class AppGradients {
  static const romantic = LinearGradient(
    colors: AppColors.gradientRomantic,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const pink = LinearGradient(
    colors: AppColors.gradientPink,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ Thêm hàm glass để sửa lỗi
  static BoxDecoration glass({double opacity = 0.15, double radius = 20}) => BoxDecoration(
    color: Colors.white.withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
