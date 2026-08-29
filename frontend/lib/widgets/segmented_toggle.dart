import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A sliding-pill toggle. Two `TextButton`s with a manually-swapped text
/// style (the original implementation) reads as an unfinished tab bar -
/// this makes the current selection an unambiguous, animated piece of UI,
/// which is a small detail that disproportionately signals polish.
class SegmentedToggle extends StatelessWidget {
  final bool isFirstSelected;
  final String firstLabel;
  final String secondLabel;
  final ValueChanged<bool> onChanged;

  const SegmentedToggle({
    super.key,
    required this.isFirstSelected,
    required this.firstLabel,
    required this.secondLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / 2;
        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: isFirstSelected ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: segmentWidth - 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _segment(context, firstLabel, isFirstSelected, () => onChanged(true)),
                  _segment(context, secondLabel, !isFirstSelected, () => onChanged(false)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segment(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: selected ? AppColors.primary : AppColors.inkMuted,
                ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
