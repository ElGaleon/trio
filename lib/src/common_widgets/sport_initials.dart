import 'package:flutter/material.dart';
import 'package:trio/src/theme/app_colors.dart';

class SportInitials extends StatelessWidget {
  const SportInitials({super.key, required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
