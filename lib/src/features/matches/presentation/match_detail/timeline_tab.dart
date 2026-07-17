import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/matches/domain/match_stat_event.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';

class TimelineSeparator extends StatelessWidget {
  final MatchStatEvent event;
  final ScrimmageMatch match;

  const TimelineSeparator({
    super.key,
    required this.event,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isGoal =
        event.type == MatchStatType.goal ||
        event.type == MatchStatType.opponentGoal;
    final isHalf =
        event.type == MatchStatType.halfTime ||
        event.type == MatchStatType.halfTimeEnd;
    final isTimeout =
        event.type == MatchStatType.timeout ||
        event.type == MatchStatType.timeoutEnd;
    final isEnd = event.type == MatchStatType.matchEnd;

    String label = '';
    Color color = AppColors.violet;
    IconData icon = FIcons.flag;

    if (isGoal) {
      final isTraining = !match.isExternalOpponent;
      label = event.type == MatchStatType.goal
          ? (isTraining ? 'Meta ${match.teamAName}' : 'Meta Noi')
          : (isTraining ? 'Meta ${match.teamBName}' : 'Meta Avversari');
      color = event.type == MatchStatType.goal
          ? AppColors.violet
          : AppColors.danger;
      icon = event.type == MatchStatType.goal ? FIcons.flag : FIcons.circleDot;
    } else if (isHalf) {
      label = 'Intervallo';
      color = AppColors.violetMid;
      icon = FIcons.timer;
    } else if (isTimeout) {
      label = 'Timeout';
      color = AppColors.violetLight;
      icon = FIcons.timer;
    } else if (isEnd) {
      label = 'Fine Partita';
      color = AppColors.violet;
      icon = FIcons.trophy;
    } else {
      return const SizedBox.shrink();
    }

    final diff = event.createdAt.difference(match.createdAt);
    final min = diff.inMinutes;
    final sec = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: SizedBox(
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                spacing: 8,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.white, size: 14),
                  Text(
                    '$label · ${event.scoreA} - ${event.scoreB} · $min\'$sec"',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeBadge extends StatelessWidget {
  const TimeBadge({super.key, required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final secStr = seconds.toString().padLeft(2, '0');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          "$minutes'$secStr\"",
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class EventIcon extends StatelessWidget {
  const EventIcon({super.key, required this.type});

  final MatchStatType type;

  @override
  Widget build(BuildContext context) {
    final destructive = type.isError || type == MatchStatType.opponentGoal;
    return SizedBox(
      width: 34,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (destructive ? AppColors.danger : AppColors.violet).withValues(
            alpha: 0.18,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: destructive ? AppColors.danger : AppColors.violetLight,
          ),
        ),
        child: Center(
          child: Icon(
            switch (type) {
              MatchStatType.goal => FIcons.flag,
              MatchStatType.opponentGoal => FIcons.circleDot,
              MatchStatType.pass => FIcons.arrowRight,
              MatchStatType.huck => FIcons.send,
              MatchStatType.pull => FIcons.send,
              MatchStatType.block || MatchStatType.defense => FIcons.shield,
              MatchStatType.timeout ||
              MatchStatType.timeoutEnd ||
              MatchStatType.halfTime ||
              MatchStatType.halfTimeEnd => FIcons.timer,
              MatchStatType.injury => FIcons.plus,
              MatchStatType.matchEnd => FIcons.trophy,
              _ => FIcons.activity,
            },
            color: AppColors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class TimelineEventRow extends StatelessWidget {
  const TimelineEventRow({
    super.key,
    required this.event,
    required this.match,
    required this.playersById,
    this.expanded = false,
  });

  final MatchStatEvent event;
  final ScrimmageMatch match;
  final Map<String, Player> playersById;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final ownSide = event.oursOnOffense || event.type == MatchStatType.goal;
    final duration = event.createdAt.difference(match.createdAt);
    final player = event.playerId == null ? null : playersById[event.playerId];
    final title = event.description ?? event.type.label;
    final subtitle = player == null
        ? 'Point #${event.pointNumber} · ${event.scoreA}-${event.scoreB}'
        : '${player.name} · Point #${event.pointNumber} · ${event.scoreA}-${event.scoreB}';
    final content = Row(
      spacing: 10,
      children: [
        TimeBadge(duration: duration),
        EventIcon(type: event.type),
        Expanded(
          child: Column(
            spacing: 3,
            crossAxisAlignment: ownSide
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: ownSide ? TextAlign.start : TextAlign.end,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (expanded)
                Text(
                  subtitle,
                  textAlign: ownSide ? TextAlign.start : TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ownSide ? content : Row(children: [Expanded(child: content)]),
    );
  }
}

class TimelineTab extends StatelessWidget {
  const TimelineTab({
    super.key,
    required this.match,
    required this.playersById,
  });

  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final events = match.statEvents
        .where((event) => event.type != MatchStatType.lineup)
        .toList()
        .reversed
        .toList();
    return GlassDecoration(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 14,
          children: [
            Text(
              'Eventi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (events.isEmpty)
              Text(
                'Nessun evento registrato',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: sportMutedText,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              ...events.expand((event) {
                final isMilestone =
                    event.type == MatchStatType.goal ||
                    event.type == MatchStatType.opponentGoal ||
                    event.type == MatchStatType.timeout ||
                    event.type == MatchStatType.halfTime ||
                    event.type == MatchStatType.matchEnd;
                return [
                  if (isMilestone)
                    TimelineSeparator(event: event, match: match),
                  TimelineEventRow(
                    event: event,
                    match: match,
                    playersById: playersById,
                    expanded: true,
                  ),
                ];
              }),
          ],
        ),
      ),
    );
  }
}
