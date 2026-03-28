import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A0A0C);
  static const surface = Color(0xFF131315);
  static const surfaceElevated = Color(0xFF1A1A1D);
  static const border = Color(0xFF252528);
  static const primary = Color(0xFFFF5C1A);
  static const primarySoft = Color(0xFF1F1208);
  static const blue = Color(0xFF3B8BFF);
  static const blueSoft = Color(0xFF0C1A33);
  static const green = Color(0xFF2ECC71);
  static const greenSoft = Color(0xFF0A1F15);
  static const red = Color(0xFFFF3B30);
  static const redSoft = Color(0xFF1F0C0A);
  static const purple = Color(0xFF9B6DFF);
  static const swiftGold = Color(0xFFFFBF00);
  static const swiftGoldSoft = Color(0xFF1F1800);
  static const textPrimary = Color(0xFFF2F2F4);
  static const textSecondary = Color(0xFF8A8A90);
  static const textTertiary = Color(0xFF4A4A52);
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.blue,
        error: AppColors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border, thickness: 0.5, space: 0),
    );
  }
}
