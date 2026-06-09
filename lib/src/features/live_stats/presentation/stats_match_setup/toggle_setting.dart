import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/theme/app_colors.dart';

class ToggleSetting extends StatelessWidget {
  const ToggleSetting({
    super.key,
    required this.title,
    required this.enabled,
    required this.detail,
    required this.onToggle,
    this.child,
  });

  final String title;
  final bool enabled;
  final String detail;
  final VoidCallback onToggle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 12,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    detail,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(
                    enabled ? FIcons.toggleRight : FIcons.toggleLeft,
                    color: enabled
                        ? AppColors.violetLight
                        : AppColors.sportMutedText,
                  ),
                ],
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}
