import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized theme.
///
/// Typography pairing: Manrope (geometric, slightly assertive) carries
/// headings and the wordmark; Inter (extremely legible at small sizes,
/// what most real product UIs use for body copy) carries everything you
/// actually read - form labels, body text, helper text. Two families used
/// with clear roles, not the same default font stretched across every size.
///
/// Every screen should pull decoration (input borders, button shape,
/// card elevation) from this theme rather than redefining
/// `OutlineInputBorder(...)` inline per-widget - that's what caused the
/// original code's login and signup forms to drift out of sync with each
/// other.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final displayFont = GoogleFonts.manropeTextTheme();
    final bodyFont = GoogleFonts.interTextTheme();

    final textTheme = bodyFont.copyWith(
      displayLarge: displayFont.displayLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
      displayMedium: displayFont.displayMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
      headlineLarge: displayFont.headlineLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
      headlineMedium: displayFont.headlineMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      headlineSmall: displayFont.headlineSmall?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      titleLarge: displayFont.titleLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      titleMedium: bodyFont.titleMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
      titleSmall: bodyFont.titleSmall?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
      bodyLarge: bodyFont.bodyLarge?.copyWith(color: AppColors.ink),
      bodyMedium: bodyFont.bodyMedium?.copyWith(color: AppColors.inkMuted),
      bodySmall: bodyFont.bodySmall?.copyWith(color: AppColors.inkFaint),
      labelLarge: bodyFont.labelLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
    );

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary, 1.6),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 1.6),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkFaint),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.inkFaint,
        suffixIconColor: AppColors.inkFaint,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }
}
