import 'package:flutter/material.dart';

/// Design tokens for the app.
///
/// Palette rationale: an account/auth surface needs to read as trustworthy
/// and calm rather than loud, so the anchor is a deep, slightly desaturated
/// teal (confidence + stability, and distinct from the generic
/// Material-blue every Flutter tutorial ships with) paired with a warm
/// ink-navy for text instead of pure black, and a soft cool-grey surface
/// instead of stark white. Amber is used as a single sparing accent for
/// things that need to stand out (badges, highlights) - not on primary
/// buttons, so it doesn't fight the teal for attention.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0E7C6B);
  static const Color primaryDark = Color(0xFF0A5C4F);
  static const Color primaryLight = Color(0xFFE3F3EF);

  // Accent (sparing use only)
  static const Color accent = Color(0xFFEDA34C);

  // Neutrals
  static const Color ink = Color(0xFF101828);
  static const Color inkMuted = Color(0xFF667085);
  static const Color inkFaint = Color(0xFF98A2B3);
  static const Color background = Color(0xFFF6F8F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E8EA);

  // Semantic
  static const Color success = Color(0xFF12B76A);
  static const Color error = Color(0xFFD92D20);
  static const Color errorSurface = Color(0xFFFEF3F2);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  static const LinearGradient avatarRing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, primary],
  );
}

/// Spacing scale - always pull from here rather than hand-writing pixel
/// values, so the whole app stays on the same rhythm.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}
