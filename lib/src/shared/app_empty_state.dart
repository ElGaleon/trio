import 'package:flutter/material.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';
import 'package:trio/src/extensions/theme_extension.dart';
import 'package:trio/theme/app_colors.dart';

class SportEmptyState extends StatelessWidget {
  const SportEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final foreground = AppColors.sportForeground(context);
    final muted = AppColors.sportMutedForeground(context);
    return GlassDecoration(
      radius: 32,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, color: AppColors.violet, size: 42),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            if (action != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: action!),
          ],
        ),
      ),
    );
  }
}
