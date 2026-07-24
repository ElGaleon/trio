import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/routing/app_router.dart';
import 'package:trio/theme/app_colors.dart';

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
    final foreground = AppColors.sportForeground(context);
    final muted = AppColors.sportMutedForeground(context);
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
                  color: AppColors.sportElevated(
                    context,
                  ).withValues(alpha: AppColors.isDark(context) ? 0.42 : 1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sportBorder(context)),
                ),
                child: Icon(FIcons.chevronLeft, color: foreground, size: 20),
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
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: muted,
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
