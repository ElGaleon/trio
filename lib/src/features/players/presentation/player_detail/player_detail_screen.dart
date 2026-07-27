import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:skrim/src/features/auth/application/auth_service.dart';
import 'package:skrim/src/features/auth/application/rbac_provider.dart';
import 'package:skrim/src/features/organizations/application/organization_invite_service.dart';
import 'package:skrim/src/features/organizations/application/organization_providers.dart';
import 'package:skrim/src/routing/app_router.dart';
import 'package:skrim/src/features/players/presentation/player_detail/player_detail_section_title.dart';
import 'package:skrim/src/features/players/presentation/player_detail/player_hero.dart';
import 'package:skrim/src/features/players/presentation/player_detail/player_match_row.dart';
import 'package:skrim/src/features/players/presentation/player_detail/stat_box.dart';
import 'package:skrim/src/features/players/presentation/ranking/rating_trend_chart.dart';
import 'package:skrim/src/shared/app_empty_state.dart';
import 'package:skrim/src/shared/sport_avatar_pill.dart';
import 'package:skrim/src/shared/sport_button.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/matches/application/matches_providers.dart';
import 'package:skrim/src/features/players/application/player_providers.dart';
import 'package:skrim/src/features/players/application/player_stats_provider.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/src/features/players/domain/player_stats_card_data.dart';

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(rankedPlayersProvider);
    Player? player;
    for (final rankedPlayer in players) {
      if (rankedPlayer.id == playerId) {
        player = rankedPlayer;
        break;
      }
    }

    if (player == null) {
      return const Scaffold(
        body: SportScreenShell(
          title: 'Player',
          subtitle: 'Profile not found',
          child: SportEmptyState(
            icon: Icons.person_off_outlined,
            title: 'Giocatore non trovato',
            message: 'Il profilo selezionato non e piu disponibile.',
          ),
        ),
      );
    }

    final currentPlayer = player;
    final matches = ref.watch(matchesProvider).where((match) {
      return match.teamAIds.contains(currentPlayer.id) ||
          match.teamBIds.contains(currentPlayer.id);
    }).toList();
    final filteredStats = ref.watch(
      playerDetailStatsProvider(currentPlayer.id),
    );
    final tournamentFilter = ref.watch(
      playerDetailTournamentFilterProvider(currentPlayer.id),
    );
    final matchFilter = ref.watch(
      playerDetailMatchFilterProvider(currentPlayer.id),
    );
    final history = _ratingHistoryForPlayer(
      currentPlayer.id,
      matches,
      ref.watch(appSettingsProvider).initialRating,
    );
    final playersById = {
      for (final rankedPlayer in players) rankedPlayer.id: rankedPlayer,
    };
    final role = ref.watch(currentRoleProvider);
    final canEdit = can(role, AppPermission.editPlayer);
    final activeOrganization = ref.watch(activeOrganizationProvider);
    final currentUser =
        FirebaseAuth.instance.currentUser ?? ref.watch(authStateProvider).value;
    final canInvite =
        activeOrganization?.ownerId == currentUser?.uid &&
        player.email.trim().isNotEmpty;

    return Scaffold(
      body: SportScreenShell(
        title: 'Player',
        subtitle: 'Performance profile',
        showBackButton: true,
        child: Column(
          spacing: 12,
          children: [
            PlayerHero(player: currentPlayer),
            _PlayerAccountStatusCard(
              player: currentPlayer,
              canInvite: canInvite,
            ),
            if (canEdit)
              Align(
                alignment: Alignment.centerLeft,
                child: SportActionButton(
                  label: 'Modifica',
                  icon: FIcons.pencil,
                  onPressed: () => context.go(
                    AppRoutes.editPlayer(currentPlayer.id),
                    extra: currentPlayer,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(
                top: 2,
              ), // 12 spacing + 2 padding = 14 total
              child: Row(
                spacing: 10,
                children: [
                  StatBox(
                    icon: FIcons.calendarCheck,
                    label: 'Partite',
                    value: '${currentPlayer.matchesPlayed}',
                  ),
                  StatBox(
                    icon: FIcons.trophy,
                    label: 'Vittorie',
                    value: '${currentPlayer.wins}',
                  ),
                  StatBox(
                    icon: FIcons.percent,
                    label: 'Win rate',
                    value: '${(currentPlayer.winRate * 100).round()}%',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ), // 12 spacing + 8 padding = 20 total
              child: const PlayerDetailSectionTitle(
                icon: FIcons.activity,
                title: 'Andamento ELO',
              ),
            ),
            GlassDecoration(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RatingTrendChart(values: history),
              ),
            ),
            if (filteredStats != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: const PlayerDetailSectionTitle(
                  icon: FIcons.chartNoAxesCombined,
                  title: 'Statistiche',
                ),
              ),
              _PlayerStatsFilters(
                playerId: currentPlayer.id,
                matches: matches,
                tournaments: filteredStats.tournaments,
                selectedTournament: tournamentFilter,
                selectedMatchId: matchFilter,
              ),
              _PlayerStatsSummary(data: filteredStats.data),
            ],
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ), // 12 spacing + 8 padding = 20 total
              child: const PlayerDetailSectionTitle(
                icon: FIcons.history,
                title: 'Partite giocate',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 2,
              ), // 12 spacing + 2 padding = 14 total (or 10)
              child: matches.isEmpty
                  ? const SportEmptyState(
                      icon: FIcons.history,
                      title: 'Nessuna partita',
                      message:
                          'Questo giocatore non ha ancora partite registrate.',
                    )
                  : Column(
                      children: matches
                          .map(
                            (match) => PlayerMatchRow(
                              player: currentPlayer,
                              match: match,
                              playersById: playersById,
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _ratingHistoryForPlayer(
    String playerId,
    List<ScrimmageMatch> matches,
    double initialRating,
  ) {
    final ordered = [...matches]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (ordered.isEmpty) return [initialRating];
    final history = <double>[
      ordered.first.initialRatings[playerId] ?? initialRating,
    ];
    for (final match in ordered) {
      history.add(match.finalRatings[playerId] ?? history.last);
    }
    return history;
  }
}

class _PlayerAccountStatusCard extends ConsumerWidget {
  const _PlayerAccountStatusCard({
    required this.player,
    required this.canInvite,
  });

  final Player player;
  final bool canInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedUserId = player.accountUserId?.trim();
    if (linkedUserId != null && linkedUserId.isNotEmpty) {
      return const _AccountStatusPanel(
        icon: Icons.verified_user_outlined,
        title: 'Account collegato',
        message: 'Questo giocatore e collegato a un account utente.',
      );
    }

    final invite = ref.watch(playerPendingInviteProvider(player.id));
    return invite.when(
      loading: () => const _AccountStatusPanel(
        icon: Icons.sync,
        title: 'Verifica account',
        message: 'Controllo se esiste un invito pendente.',
      ),
      error: (error, stackTrace) => const _AccountStatusPanel(
        icon: Icons.error_outline,
        title: 'Stato account non disponibile',
        message: 'Non riesco a verificare inviti o collegamenti.',
      ),
      data: (invite) {
        if (invite != null && !invite.isExpired) {
          return _AccountStatusPanel(
            icon: Icons.mark_email_unread_outlined,
            title: 'Invito pendente',
            message: 'Invito inviato a ${invite.email}.',
            action: canInvite
                ? SportActionButton(
                    label: 'Rigenera invito',
                    icon: Icons.refresh,
                    onPressed: () => _sendInvite(context, ref),
                  )
                : null,
          );
        }
        final hasEmail = player.email.trim().isNotEmpty;
        return _AccountStatusPanel(
          icon: Icons.person_add_disabled_outlined,
          title: 'Nessun account collegato',
          message: hasEmail
              ? 'Nessun invito attivo per ${player.email}.'
              : 'Aggiungi una mail al giocatore per poterlo invitare.',
          action: canInvite && hasEmail
              ? SportActionButton(
                  label: 'Invita giocatore',
                  icon: Icons.mail_outline,
                  onPressed: () => _sendInvite(context, ref),
                )
              : null,
        );
      },
    );
  }

  Future<void> _sendInvite(BuildContext context, WidgetRef ref) async {
    final organizationId = ref.read(activeOrganizationIdProvider);
    if (organizationId == null) return;
    try {
      await ref
          .read(organizationInviteServiceProvider)
          .invitePlayer(
            organizationId: organizationId,
            playerId: player.id,
            email: player.email,
          );
      ref.invalidate(playerPendingInviteProvider(player.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invito rigenerato.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _AccountStatusPanel extends StatelessWidget {
  const _AccountStatusPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassDecoration(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          spacing: 12,
          children: [
            Icon(icon, color: AppColors.violet, size: 22),
            Expanded(
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    message,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedForeground(context),
                    ),
                  ),
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class _PlayerStatsFilters extends ConsumerWidget {
  const _PlayerStatsFilters({
    required this.playerId,
    required this.matches,
    required this.tournaments,
    required this.selectedTournament,
    required this.selectedMatchId,
  });

  final String playerId;
  final List<ScrimmageMatch> matches;
  final List<String> tournaments;
  final String? selectedTournament;
  final String? selectedMatchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleMatches = selectedTournament == null
        ? matches
        : matches
              .where((match) => match.tournament.trim() == selectedTournament)
              .toList();

    return Column(
      spacing: 8,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: 8,
            children: [
              SportFilterPill(
                label: 'Tutti tornei',
                selected: selectedTournament == null,
                onPressed: () {
                  ref
                      .read(
                        playerDetailTournamentFilterProvider(playerId).notifier,
                      )
                      .set(null);
                  ref
                      .read(playerDetailMatchFilterProvider(playerId).notifier)
                      .set(null);
                },
              ),
              for (final tournament in tournaments)
                SportFilterPill(
                  label: tournament,
                  selected: selectedTournament == tournament,
                  onPressed: () {
                    ref
                        .read(
                          playerDetailTournamentFilterProvider(
                            playerId,
                          ).notifier,
                        )
                        .set(tournament);
                    ref
                        .read(
                          playerDetailMatchFilterProvider(playerId).notifier,
                        )
                        .set(null);
                  },
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: 8,
            children: [
              SportFilterPill(
                label: 'Tutte partite',
                selected: selectedMatchId == null,
                onPressed: () => ref
                    .read(playerDetailMatchFilterProvider(playerId).notifier)
                    .set(null),
              ),
              for (final match in visibleMatches)
                SportFilterPill(
                  label: _matchFilterLabel(match),
                  selected: selectedMatchId == match.id,
                  onPressed: () => ref
                      .read(playerDetailMatchFilterProvider(playerId).notifier)
                      .set(match.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerStatsSummary extends StatelessWidget {
  const _PlayerStatsSummary({required this.data});

  final PlayerStatsCardData data;

  @override
  Widget build(BuildContext context) {
    return GlassDecoration(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          spacing: 6,
          children: [
            _CompactStatRow(
              items: [
                ('+/-', _signed(data.plusMinus)),
                ('PT', '${data.pointsPlayed}'),
                ('Tocchi', '${data.touches}'),
              ],
            ),
            _CompactStatRow(
              items: [
                ('Mete', '${data.goals}'),
                ('Assist', '${data.assists}'),
                ('Difese', '${data.defenses}'),
              ],
            ),
            _CompactStatRow(
              items: [
                ('Tocchi/PT', _percent(data.touchesPerPoint)),
                ('Mete/PT', _percent(data.goalsPerPoint)),
                ('Assist/PT', _percent(data.assistsPerPoint)),
              ],
            ),
            _CompactStatRow(
              items: [
                ('Errori', '${data.errors}'),
                ('Pull dentro', _percent(data.pullInRate)),
                (
                  'Pull medio',
                  '${data.averagePullSeconds.toStringAsFixed(1)}s',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStatRow extends StatelessWidget {
  const _CompactStatRow({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      children: [
        for (final item in items)
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.sportForeground(
                  context,
                ).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.sportForeground(
                    context,
                  ).withValues(alpha: 0.09),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.sportForeground(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: sportMutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

String _matchFilterLabel(ScrimmageMatch match) {
  final tournament = match.tournament.trim();
  final prefix = tournament.isEmpty ? _dateLabel(match.createdAt) : tournament;
  return '$prefix · ${match.scoreA}-${match.scoreB}';
}

String _percent(double value) => '${(value * 100).round()}%';

String _signed(double value) {
  final rounded = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 1,
  );
  return value > 0 ? '+$rounded' : rounded;
}
