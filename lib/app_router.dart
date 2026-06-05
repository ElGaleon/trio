import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/model/player.dart';
import 'package:trio/model/scrimmage_match.dart';
import 'package:trio/screens/home_screen.dart';
import 'package:trio/screens/login_screen.dart';
import 'package:trio/screens/matches_screen.dart';
import 'package:trio/screens/players_screen.dart';
import 'package:trio/screens/player_stats_screen.dart';
import 'package:trio/screens/ranking_screen.dart';
import 'package:trio/screens/settings_screen.dart';
import 'package:trio/screens/match_detail_screen.dart';
import 'package:trio/screens/match_form_screen.dart';
import 'package:trio/screens/player_detail_screen.dart';
import 'package:trio/screens/player_form_screen.dart';
import 'package:trio/screens/live_stats_screen.dart';
import 'package:trio/screens/stats_match_setup_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
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
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggingIn = state.matchedLocation == AppRoutes.login;

    if (user == null) {
      return isLoggingIn ? null : AppRoutes.login;
    }

    if (isLoggingIn) {
      return AppRoutes.ranking;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
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
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
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
      ],
    ),
  ],
);
