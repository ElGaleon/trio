import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/theme/app_colors.dart';

class SportActionButton extends StatelessWidget {
  const SportActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = FIcons.plus,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        height: 36,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: enabled ? 0.24 : 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.violet.withValues(alpha: enabled ? 1 : 0.36),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Icon(
                  icon,
                  color: AppColors.white.withValues(alpha: enabled ? 1 : 0.55),
                  size: 16,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(
                      alpha: enabled ? 1 : 0.55,
                    ),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SportFloatingActionButton extends StatelessWidget {
  const SportFloatingActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = FIcons.plus,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return SportActionButton(label: label, icon: icon, onPressed: onPressed);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.violet,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.42),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Icon(icon, color: AppColors.white, size: 20),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SportBackButton extends StatelessWidget {
  const SportBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.matches);
          }
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.14),
              ),
            ),
            child: const Center(
              child: Icon(FIcons.chevronLeft, color: AppColors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
