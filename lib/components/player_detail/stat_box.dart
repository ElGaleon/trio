import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../shared/sport_avatar_pill.dart';

class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: DecoratedBox(
        decoration: sportGlassDecoration(radius: 22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.violet),
              Padding(
                padding: const EdgeInsets.only(top: 2), // Adjust gap to match 10 (8 spacing + 2 padding)
                child: Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
