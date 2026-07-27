import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';

class FormNavButton extends StatelessWidget {
  const FormNavButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined
              ? AppColors.white.withValues(alpha: enabled ? 0.08 : 0.04)
              : AppColors.violet.withValues(alpha: enabled ? 1 : 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: outlined
                ? AppColors.white.withValues(alpha: 0.14)
                : AppColors.violet.withValues(alpha: enabled ? 1 : 0.35),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.sportForeground(
              context,
            ).withValues(alpha: enabled ? 1 : 0.45),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
