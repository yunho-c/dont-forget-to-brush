import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'app_colors.dart';

class AppTheme {
  static shadcn.ThemeData shadcnDark() {
    return shadcn.ThemeData.dark(
      colorScheme: shadcn.ColorScheme(
        brightness: material.Brightness.dark,
        background: AppColors.night950,
        foreground: material.Colors.white,
        card: AppColors.night800,
        cardForeground: material.Colors.white,
        popover: AppColors.night800,
        popoverForeground: material.Colors.white,
        primary: AppColors.indigo500,
        primaryForeground: material.Colors.white,
        secondary: AppColors.night700,
        secondaryForeground: material.Colors.white,
        muted: AppColors.night700,
        mutedForeground: AppColors.slate400,
        accent: AppColors.indigo500.withValues(alpha: 0.2),
        accentForeground: material.Colors.white,
        destructive: AppColors.red600,
        destructiveForeground: material.Colors.white,
        border: AppColors.night700,
        input: AppColors.night700,
        ring: AppColors.indigo500,
        chart1: AppColors.indigo500,
        chart2: AppColors.green500,
        chart3: AppColors.orange400,
        chart4: AppColors.slate400,
        chart5: AppColors.red500,
        sidebar: AppColors.night900,
        sidebarForeground: material.Colors.white,
        sidebarPrimary: AppColors.indigo500,
        sidebarPrimaryForeground: material.Colors.white,
        sidebarAccent: AppColors.night800,
        sidebarAccentForeground: material.Colors.white,
        sidebarBorder: AppColors.night700,
        sidebarRing: AppColors.indigo500,
      ),
      radius: 0.7,
      scaling: 1,
      typography: const shadcn.Typography.geist(),
    );
  }

  static material.ThemeData materialDark() {
    final base = material.ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.night950,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.indigo500,
        secondary: AppColors.indigo600,
        surface: AppColors.night800,
        error: AppColors.red600,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: material.FontWeight.w700,
          color: material.Colors.white,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: material.FontWeight.w600,
          color: material.Colors.white,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: material.Colors.white,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: AppColors.slate400,
        ),
      ),
    );
  }
}
