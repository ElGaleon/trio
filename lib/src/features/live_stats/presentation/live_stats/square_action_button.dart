import 'package:flutter/material.dart';
import 'package:trio/theme/app_colors.dart';

class SquareActionButton extends StatelessWidget {
  const SquareActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final accent = danger ? AppColors.danger : AppColors.violetLight;
    return Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.38,
          child: SizedBox(
            width: 52,
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.72)),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: AppColors.sportForeground(context),
                  size: 19,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
