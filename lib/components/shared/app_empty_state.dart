import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'sport_avatar_pill.dart';

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
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: sportGlassDecoration(radius: 32),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          spacing: 8,
          children: [
            Icon(icon, color: AppColors.violet, size: 42),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.sportMutedText),
            ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: action!,
              ),
          ],
        ),
      ),
    );
  }
}
