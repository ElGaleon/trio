import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:skrim/src/components/ui/responsive_grid.dart';

import 'package:skrim/src/shared/app_empty_state.dart';
import 'package:skrim/src/shared/decorated_panel.dart';
import 'package:skrim/src/shared/match_card.dart';
import 'package:skrim/src/shared/sport_button.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/src/constants/app_constants.dart';
import 'package:skrim/src/features/auth/application/rbac_provider.dart';
import 'package:skrim/src/routing/app_router.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:skrim/src/features/events/application/events_providers.dart';
import 'package:skrim/src/features/matches/application/matches_providers.dart';
import 'package:skrim/src/features/matches/application/matches_view_mode.dart';
import 'match_date_filters.dart';
import 'match_toolbar.dart';
import 'matches_calendar_view.dart';
import 'matches_header_view_switch.dart';
import 'popup_option.dart';
import 'package:skrim/src/features/players/application/player_providers.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(firestoreSkrimRepositoryProvider);
    final matches = ref.watch(matchesProvider);
    final filteredMatches = ref.watch(filteredMatchesProvider);
    final eventIds = {
      for (final event in ref.watch(eventsProvider)) event.storageId,
    };
    final startDate = ref.watch(matchesStartDateFilterProvider);
    final endDate = ref.watch(matchesEndDateFilterProvider);
    final viewMode = ref.watch(matchesViewModeProvider);
    final players = ref.watch(rankedPlayersProvider);
    final role = ref.watch(currentRoleProvider);
    final canCreate =
        can(role, AppPermission.createMatch) &&
        players.length >= AppConstants.minTeamSize * 2;
    final canEdit = can(role, AppPermission.editMatch);
    final canDelete = can(role, AppPermission.deleteMatch);
    final canOpenLive = can(role, AppPermission.recordLiveStats);
    final hasFilters = startDate != null || endDate != null;
    final now = DateTime.now();

    return SportScreenShell(
      title: 'Matches',
      subtitle: 'Track every scrimmage',
      headerActions: [
        MatchesHeaderViewSwitch(
          selected: viewMode,
          onChanged: (mode) =>
              ref.read(matchesViewModeProvider.notifier).set(mode),
        ),
      ],
      floatingActionButton: can(role, AppPermission.createMatch)
          ? SportFloatingActionButton(
              label: 'Nuova',
              onPressed: () => _openMatchForm(context, canCreate),
            )
          : null,
      child: matches.isEmpty
          ? const SportEmptyState(
              icon: Icons.scoreboard_outlined,
              title: 'Nessuna partitella',
              message: 'Inserisci il risultato della prima partitella.',
            )
          : SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 8,
                children: [
                  MatchToolbar(
                    totalCount: matches.length,
                    filteredCount: filteredMatches.length,
                    hasFilters: hasFilters,
                    canCreate: canCreate,
                  ),
                  if (viewMode == MatchesViewMode.list) ...[
                    MatchDateFilters(
                      startDate: startDate,
                      endDate: endDate,
                      onStartChanged: (value) => ref
                          .read(matchesStartDateFilterProvider.notifier)
                          .set(value),
                      onEndChanged: (value) => ref
                          .read(matchesEndDateFilterProvider.notifier)
                          .set(value),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: filteredMatches.isEmpty
                          ? const SportEmptyState(
                              icon: Icons.event_busy_outlined,
                              title: 'Nessuna partita',
                              message:
                                  'Non ci sono partite nel periodo selezionato.',
                            )
                          : ResponsiveGrid(
                              minTileWidth: 360,
                              children: filteredMatches.map((match) {
                                final liveNow = match.isLiveAt(now);
                                final planned =
                                    !liveNow &&
                                    (eventIds.contains(match.eventId) ||
                                        eventIds.contains(
                                          match.trainingEventId,
                                        ));
                                return MatchCard(
                                  match: match,
                                  highlighted: liveNow,
                                  planned: planned,
                                  onTap: () => context.go(
                                    AppRoutes.matchDetail(match.id),
                                  ),
                                  onEdit: canEdit
                                      ? () => context.go(
                                          AppRoutes.editMatch(match.id),
                                          extra: match,
                                        )
                                      : null,
                                  onDelete: canDelete
                                      ? () => repository?.deleteMatch(match.id)
                                      : null,
                                  onLive: canOpenLive && liveNow
                                      ? () => context.go(
                                          AppRoutes.liveStats(match.id),
                                        )
                                      : null,
                                );
                              }).toList(),
                            ),
                    ),
                  ] else
                    MatchesCalendarView(
                      onEdit: canEdit
                          ? (match) => context.go(
                              AppRoutes.editMatch(match.id),
                              extra: match,
                            )
                          : null,
                      onDelete: canDelete
                          ? (match) => repository?.deleteMatch(match.id)
                          : null,
                    ),
                ],
              ),
            ),
    );
  }

  void _openMatchForm(BuildContext context, bool canCreate) {
    if (!canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servono almeno 6 giocatori per creare un 3vs3.'),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: DecoratedPanel(
            radius: 28,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuova Partita',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.sportForeground(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Scegli il tipo di partita da registrare',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.sportMutedForeground(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: PopupOption(
                        icon: FIcons.plus,
                        title: 'Partita Rapida (Solo Risultato & ELO)',
                        subtitle: 'Inserisci a posteriori il risultato finale',
                        onTap: () {
                          Navigator.pop(context);
                          context.go(AppRoutes.newMatch);
                        },
                      ),
                    ),
                    PopupOption(
                      icon: FIcons.users,
                      title: 'Partita di Allenamento (Stats)',
                      subtitle:
                          'Traccia statistiche in tempo reale per partitella interna',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('${AppRoutes.newStatsMatch}?type=training');
                      },
                    ),
                    PopupOption(
                      icon: FIcons.activity,
                      title: 'Partita Ufficiale (Stats & vs Altri)',
                      subtitle: 'Traccia statistiche in tempo reale vs esterni',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('${AppRoutes.newStatsMatch}?type=official');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
