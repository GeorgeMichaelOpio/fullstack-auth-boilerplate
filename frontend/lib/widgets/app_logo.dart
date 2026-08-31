import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Placeholder brand mark. Swap the icon/wordmark for your real logo asset -
/// this exists so the auth screen has a focal point that isn't a stock
/// background photo, and so branding lives in exactly one widget.
class AppLogo extends StatelessWidget {
  final double size;
  final bool light;
  const AppLogo({super.key, this.size = 44, this.light = false});

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? Colors.white.withOpacity(0.16) : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: fg, size: size * 0.52),
        ),
        SizedBox(width: size * 0.28),
        Text(
          'Flutter Auth Demo',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: light ? Colors.white : AppColors.ink,
                letterSpacing: -0.5,
              ),
        ),
      ],
    );
  }
}
