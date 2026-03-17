import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF13131A);
  static const surfaceElevated = Color(0xFF1C1C26);
  static const surfaceBorder = Color(0xFF252532);

  static const primary = Color(0xFF7C6FFF);
  static const primaryLight = Color(0xFF9B91FF);
  static const primarySurface = Color(0xFF1A1830);
  static const primaryBorder = Color(0xFF3D3680);

  static const accent = Color(0xFF2FD0C5);
  static const accentLight = Color(0xFF5DDDD4);
  static const accentSurface = Color(0xFF0D2626);
  static const accentBorder = Color(0xFF1A5550);

  static const textPrimary = Color(0xFFEEEEF5);
  static const textSecondary = Color(0xFF8888A0);
  static const textTertiary = Color(0xFF44445A);

  static const error = Color(0xFFFF6B8A);
  static const errorSurface = Color(0xFF2A1020);
  static const success = Color(0xFF4ADE80);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        fontFamily: 'SF Pro Display',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1.1,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
          labelSmall: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.accentBorder, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      );
}