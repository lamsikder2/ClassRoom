import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const List<String> fontFallbacks = [
    'Noto Sans Bengali',
    'SolaimanLipi',
    'Kalpurush',
    'sans-serif',
  ];

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = GoogleFonts.hindSiliguriTextTheme(baseTextTheme).copyWith(
      headlineLarge: GoogleFonts.hindSiliguri(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.neutral900,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      headlineMedium: GoogleFonts.hindSiliguri(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.neutral900,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      titleLarge: GoogleFonts.hindSiliguri(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral900,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      titleMedium: GoogleFonts.hindSiliguri(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral900,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      bodyLarge: GoogleFonts.hindSiliguri(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.neutral800,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      bodyMedium: GoogleFonts.hindSiliguri(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.neutral700,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      bodySmall: GoogleFonts.hindSiliguri(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.neutral500,
      ).copyWith(fontFamilyFallback: fontFallbacks),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary600,
      scaffoldBackgroundColor: AppColors.neutral50,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary600,
        primaryContainer: AppColors.primary100,
        secondary: AppColors.teal600,
        surface: AppColors.neutral0,
        error: AppColors.error,
        onPrimary: AppColors.neutral0,
        onSecondary: AppColors.neutral0,
        onSurface: AppColors.neutral900,
        onError: AppColors.neutral0,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.neutral0,
        foregroundColor: AppColors.neutral900,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.neutral0,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.neutral200, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral200,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: AppColors.neutral0,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary600,
          side: const BorderSide(color: AppColors.primary600, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.neutral0,
        selectedItemColor: AppColors.primary600,
        unselectedItemColor: AppColors.neutral500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary600, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.hindSiliguriTextTheme(baseTextTheme).copyWith(
      headlineLarge: GoogleFonts.hindSiliguri(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.neutral0,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      headlineMedium: GoogleFonts.hindSiliguri(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.neutral0,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      titleLarge: GoogleFonts.hindSiliguri(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral0,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      titleMedium: GoogleFonts.hindSiliguri(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral100,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      bodyLarge: GoogleFonts.hindSiliguri(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.neutral100,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      bodyMedium: GoogleFonts.hindSiliguri(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.neutral300,
      ).copyWith(fontFamilyFallback: fontFallbacks),
      bodySmall: GoogleFonts.hindSiliguri(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.neutral400,
      ).copyWith(fontFamilyFallback: fontFallbacks),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary300,
      scaffoldBackgroundColor: AppColors.neutral950,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary300,
        primaryContainer: AppColors.primary800,
        secondary: AppColors.teal500,
        surface: AppColors.neutral900,
        error: AppColors.errorDark,
        onPrimary: AppColors.neutral950,
        onSecondary: AppColors.neutral950,
        onSurface: AppColors.neutral0,
        onError: AppColors.neutral950,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.neutral900,
        foregroundColor: AppColors.neutral0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.neutral900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.neutral800, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral800,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary400,
          foregroundColor: AppColors.neutral950,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.neutral900,
        selectedItemColor: AppColors.primary300,
        unselectedItemColor: AppColors.neutral400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

