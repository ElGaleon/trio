import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/shared/decorated_panel.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/firebase/data/firestore_trio_repository.dart';
import 'package:trio/src/features/settings/domain/app_settings.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/live_stats/application/live_stats_service.dart';
import 'general_action_button.dart';

class HalfTimePrompt {
  const HalfTimePrompt._();

  static Future<void> show(
    BuildContext context,
    LiveStatsService service,
    ScrimmageMatch match,
    Map<String, Player> playersById,
    FirestoreTrioRepository repository,
    AppSettings settings,
  ) async {
    if (service.hasHalfTimeEvent(match)) return;
    final start = await showModalBottomSheet<bool>(
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
                    'Half time',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Siete arrivati alla metà partita. Vuoi avviare il countdown ora?',
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
                          label: 'SKIP',
                          icon: FIcons.x,
                          accent: AppColors.appDarkElevated,
                          compact: true,
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ),
                      Expanded(
                        child: GeneralActionButton(
                          label: 'START',
                          icon: FIcons.play,
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
    if (start != true) return;
    if (!context.mounted) return;
    await service.record(
      match,
      type: MatchStatType.halfTime,
      playersById: playersById,
      repository: repository,
      settings: settings,
    );
  }
}
