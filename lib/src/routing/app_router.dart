import 'package:go_router/go_router.dart';
import 'package:trio/src/features/home/presentation/home_screen.dart';
import 'package:trio/src/features/live_stats/presentation/live_stats/live_stats_screen.dart';
import 'package:trio/src/features/live_stats/presentation/stats_match_setup/stats_match_setup_screen.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/presentation/match_detail/match_detail_screen.dart';
import 'package:trio/src/features/matches/presentation/match_form/match_form_screen.dart';
import 'package:trio/src/features/matches/presentation/matches/matches_screen.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/presentation/player_detail/player_detail_screen.dart';
import 'package:trio/src/features/players/presentation/player_form/player_form_screen.dart';
import 'package:trio/src/features/players/presentation/player_stats/player_stats_screen.dart';
import 'package:trio/src/features/players/presentation/players/players_screen.dart';
import 'package:trio/src/features/players/presentation/ranking/ranking_screen.dart';
import 'package:trio/src/features/settings/presentation/settings_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const ranking = '/ranking';
  static const matches = '/matches';
  static const players = '/players';
  static const stats = '/stats';
  static const settings = '/settings';

  static const newMatch = '/matches/new';
  static const newStatsMatch = '/matches/new_stats';
  static const newPlayer = '/players/new';

  static String matchDetail(String id) => '/matches/$id';
  static String editMatch(String id) => '/matches/$id/edit';
  static String liveStats(String id) => '/matches/$id/live';
  static String playerDetail(String id) => '/players/$id';
  static String editPlayer(String id) => '/players/$id/edit';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.ranking,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.ranking,
              builder: (context, state) => const RankingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.matches,
              builder: (context, state) => const MatchesScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const MatchFormScreen(),
                ),
                GoRoute(
                  path: 'new_stats',
                  builder: (context, state) => const StatsMatchSetupScreen(),
                ),
                GoRoute(
                  path: ':matchId',
                  builder: (context, state) {
                    final matchId = state.pathParameters['matchId']!;
                    return MatchDetailScreen(matchId: matchId);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) {
                        final matchId = state.pathParameters['matchId']!;
                        final extraMatch = state.extra is ScrimmageMatch
                            ? state.extra as ScrimmageMatch
                            : null;
                        return MatchFormScreen(
                          matchId: matchId,
                          match: extraMatch,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'live',
                      builder: (context, state) {
                        final matchId = state.pathParameters['matchId']!;
                        return LiveStatsScreen(matchId: matchId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.players,
              builder: (context, state) => const PlayersScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const PlayerFormScreen(),
                ),
                GoRoute(
                  path: ':playerId',
                  builder: (context, state) {
                    final playerId = state.pathParameters['playerId']!;
                    return PlayerDetailScreen(playerId: playerId);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) {
                        final playerId = state.pathParameters['playerId']!;
                        final extraPlayer = state.extra is Player
                            ? state.extra as Player
                            : null;
                        return PlayerFormScreen(
                          playerId: playerId,
                          player: extraPlayer,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.stats,
              builder: (context, state) => const PlayerStatsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
