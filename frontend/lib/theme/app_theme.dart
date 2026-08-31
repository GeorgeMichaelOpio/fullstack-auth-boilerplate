import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized theme, built once for light and once for dark from the same
/// structure so the two never drift into inconsistent shapes/paddings -
/// only the color tokens differ.
///
/// Typography pairing: Manrope (geometric, slightly assertive) carries
/// headings and the wordmark; Inter (extremely legible at small sizes,
/// what most real product UIs use for body copy) carries everything you
/// actually read.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: AppColors.background,
        surface: AppColors.surface,
        border: AppColors.border,
        ink: AppColors.ink,
        inkMuted: AppColors.inkMuted,
        inkFaint: AppColors.inkFaint,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        border: AppColors.darkBorder,
        ink: AppColors.darkInk,
        inkMuted: AppColors.darkInkMuted,
        inkFaint: AppColors.darkInkFaint,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color border,
    required Color ink,
    required Color inkMuted,
    required Color inkFaint,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: surface,
        error: AppColors.error,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: background,
    );

    final displayFont = GoogleFonts.manropeTextTheme();
    final bodyFont = GoogleFonts.interTextTheme();

    final textTheme = bodyFont.copyWith(
      displayLarge: displayFont.displayLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
      displayMedium: displayFont.displayMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
      headlineLarge: displayFont.headlineLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
      headlineMedium: displayFont.headlineMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
      headlineSmall: displayFont.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
      titleLarge: displayFont.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w700),
      titleMedium: bodyFont.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w600),
      titleSmall: bodyFont.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w600),
      bodyLarge: bodyFont.bodyLarge?.copyWith(color: ink),
      bodyMedium: bodyFont.bodyMedium?.copyWith(color: inkMuted),
      bodySmall: bodyFont.bodySmall?.copyWith(color: inkFaint),
      labelLarge: bodyFont.labelLarge?.copyWith(color: ink, fontWeight: FontWeight.w600),
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(AppColors.primary, 1.6),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 1.6),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: inkFaint),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        prefixIconColor: inkFaint,
        suffixIconColor: inkFaint,
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
        style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: textTheme.labelLarge),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }
}
