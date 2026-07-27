import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.textTheme,
  });

  final IconData icon;
  final String title;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Icon(icon, color: AppColors.violet, size: 18),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.sportForeground(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
