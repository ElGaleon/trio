import 'package:flutter/material.dart';
import '../../model/scrimmage_match.dart';
import '../../theme/app_colors.dart';
import '../shared/sport_avatar_pill.dart';
import '../shared/sport_screen_shell.dart';

class CountdownBanner extends StatelessWidget {
  const CountdownBanner({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.violetLight.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.violetLight,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveScoreHeader extends StatelessWidget {
  const LiveScoreHeader({
    super.key,
    required this.match,
    required this.point,
    required this.oursOnOffense,
    required this.discHolderName,
    required this.matchRemaining,
    required this.timeoutRemaining,
    required this.halfTimeRemaining,
    required this.halfTimeDue,
    required this.onHalfTime,
  });

  final ScrimmageMatch match;
  final int point;
  final bool oursOnOffense;
  final String? discHolderName;
  final Duration matchRemaining;
  final Duration? timeoutRemaining;
  final Duration? halfTimeRemaining;
  final bool halfTimeDue;
  final VoidCallback? onHalfTime;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: sportGlassDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 10,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${match.teamAName}\n${_format(matchRemaining)}',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${match.scoreA} - ${match.scoreB}',
                  style: textTheme.displaySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Expanded(
                  child: Text(
                    match.teamBName,
                    textAlign: TextAlign.end,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (timeoutRemaining != null || halfTimeRemaining != null)
              CountdownBanner(
                label: halfTimeRemaining != null ? 'HALF TIME' : 'TIMEOUT',
                value: _format(halfTimeRemaining ?? timeoutRemaining!),
              )
            else if (halfTimeDue)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onHalfTime,
                child: const CountdownBanner(label: 'HALF TIME', value: 'START'),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Point #$point · ${oursOnOffense ? 'ATTACCO' : 'DIFESA'}'
                    '${oursOnOffense ? ' · Disco: ${discHolderName ?? 'seleziona'}' : ''}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: oursOnOffense && discHolderName == null
                          ? AppColors.violetLight
                          : sportMutedText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final total = duration.inSeconds.clamp(0, 24 * 60 * 60);
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
