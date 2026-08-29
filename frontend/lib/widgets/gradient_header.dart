import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ambient gradient header used behind the auth card and behind the profile
/// screen's app bar.
///
/// The original screen used `AssetImage('assets/img.jpg')` as a full-screen
/// background - fragile (the build silently shows a grey box if that asset
/// is ever missing/renamed) and visually generic (a random stock photo).
/// This paints a deliberate, on-brand gradient with two soft blurred
/// accent shapes instead, so it never breaks and always matches the theme.
class GradientHeader extends StatelessWidget {
  final double height;
  final Widget? child;

  const GradientHeader({super.key, required this.height, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: _blurredBlob(180, Colors.white.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _blurredBlob(220, AppColors.accent.withOpacity(0.22)),
          ),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }

  Widget _blurredBlob(double diameter, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
