import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../theme/app_colors.dart';

class AppHeader extends StatelessWidget {
  final bool showBackButton;
  final bool showSettingsButton;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.showSettingsButton = false,
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      spacing: 8,
      children: [
        if (showBackButton)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap:
                onBack ??
                () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.matches);
                  }
                },
            child: SizedBox.square(
              dimension: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  FIcons.chevronLeft,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                title,
                style: textTheme.displaySmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.sportMutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}
