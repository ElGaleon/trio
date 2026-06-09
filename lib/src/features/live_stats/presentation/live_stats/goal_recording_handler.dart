import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/common_widgets/decorated_panel.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/matches/data/elo_repository.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/live_stats/application/live_stats_service.dart';
import 'general_action_button.dart';
import 'half_time_prompt.dart';

class GoalRecordingHandler {
  const GoalRecordingHandler._();

  static Future<void> confirmAndRecord(
    BuildContext context, {
    required LiveStatsService service,
    required ScrimmageMatch match,
    required MatchStatType type,
    required Map<String, Player> playersById,
    required EloRepository repository,
    required Future<void> Function() onFinish,
    required Future<void> Function(bool nextOnOffense) onShowLineSelection,
  }) async {
    final nextScoreA = match.scoreA + (type == MatchStatType.goal ? 1 : 0);
    final nextScoreB =
        match.scoreB + (type == MatchStatType.opponentGoal ? 1 : 0);
    final closesMatch =
        nextScoreA >= match.pointsLimit || nextScoreB >= match.pointsLimit;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: DecoratedPanel(
            radius: 28,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    closesMatch ? 'Conferma fine match' : 'Conferma meta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    closesMatch
                        ? 'Il punteggio diventa $nextScoreA - $nextScoreB and la partita arriva al limite di ${match.pointsLimit}.'
                        : 'Il punteggio diventa $nextScoreA - $nextScoreB. Confermi?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.sportMutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: GeneralActionButton(
                          label: 'ANNULLA',
                          icon: FIcons.x,
                          accent: AppColors.appDarkElevated,
                          compact: true,
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ),
                      Expanded(
                        child: GeneralActionButton(
                          label: 'CONFERMA',
                          icon: FIcons.check,
                          accent: AppColors.violet,
                          compact: true,
                          onTap: () => Navigator.pop(context, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final res = await service.record(
      match,
      type: type,
      playersById: playersById,
      repository: repository,
    );
    if (!context.mounted) return;
    if (res.finished) {
      await onFinish();
      return;
    }
    if (res.halfTimeDue) {
      await HalfTimePrompt.show(context, service, match, playersById, repository);
    }
    if (!context.mounted) return;
    if (res.scoredPoint && context.mounted) {
      await onShowLineSelection(res.oursOnOffense);
    }
  }
}
