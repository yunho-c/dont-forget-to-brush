import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.night900,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.indigo500,
        secondary: AppColors.indigo600,
        surface: AppColors.night800,
        error: AppColors.red600,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: Colors.white),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: AppColors.slate400,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.night800,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.night700,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.night800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.night700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.night700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.indigo500),
        ),
        hintStyle: const TextStyle(color: AppColors.slate400),
      ),
    );
  }
}
