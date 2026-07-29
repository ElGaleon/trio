import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:skrim/src/extensions/theme_extension.dart';
import 'package:skrim/theme/app_colors.dart';

class PullTimerDisplay extends StatelessWidget {
  const PullTimerDisplay({
    super.key,
    required this.elapsed,
    required this.running,
  });

  final Duration elapsed;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes;
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final tenths = ((elapsed.inMilliseconds % 1000) ~/ 100).toString();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sportForeground(context).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: running
              ? AppColors.violet
              : AppColors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 16,
          children: [
            Icon(
              running ? FIcons.timer : FIcons.timerReset,
              color: running ? AppColors.violetLight : AppColors.sportMutedText,
              size: 22,
            ),
            Expanded(
              child: Text(
                '$minutes:$seconds.$tenths',
                style: context.textTheme.displaySmall?.copyWith(
                  color: AppColors.sportForeground(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              running ? 'LIVE' : 'READY',
              style: context.textTheme.bodySmall?.copyWith(
                color: running
                    ? AppColors.violetLight
                    : AppColors.sportMutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
