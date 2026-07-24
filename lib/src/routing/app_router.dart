import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/src/features/auth/application/rbac_provider.dart';
import 'package:trio/src/features/auth/presentation/user_profile_screen.dart';
import 'package:trio/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:trio/src/features/events/presentation/events_screen.dart';
import 'package:trio/screens/login_screen.dart';
import 'package:trio/src/features/home/presentation/home_screen.dart';
import 'package:trio/src/features/live_stats/presentation/live_stats/live_stats_screen.dart';
import 'package:trio/src/features/live_stats/presentation/stats_match_setup/stats_match_setup_screen.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/presentation/match_detail/match_detail_screen.dart';
import 'package:trio/src/features/matches/presentation/match_form/match_form_screen.dart';
import 'package:trio/src/features/matches/presentation/matches/matches_screen.dart';
import 'package:trio/src/features/organizations/presentation/organization_management_screen.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/presentation/player_detail/player_detail_screen.dart';
import 'package:trio/src/features/players/presentation/player_form/player_form_screen.dart';
import 'package:trio/src/features/players/presentation/my_stats/my_stats_screen.dart';
import 'package:trio/src/features/players/presentation/player_stats/player_stats_screen.dart';
import 'package:trio/src/features/players/presentation/players/players_screen.dart';
import 'package:trio/src/features/players/presentation/ranking/ranking_screen.dart';
import 'package:trio/src/features/settings/presentation/settings_screen.dart';
import 'package:trio/src/shared/responsive_layout.dart';

class AppRoutes {
  const AppRoutes._();

  static const dashboard = '/dashboard';
  static const ranking = '/ranking';
  static const login = '/login';
  static const matches = '/matches';
  static const players = '/players';
  static const me = '/me';
  static const stats = '/stats';
  static const settings = '/settings';
  static const profile = '/profile';
  static const organization = '/settings/organization';
  static const events = '/events';

  static const newMatch = '/matches/new';
  static const newStatsMatch = '/matches/new_stats';
  static const newPlayer = '/players/new';

  static String matchDetail(String id) => '/matches/$id';
  static String editMatch(String id) => '/matches/$id/edit';
  static String liveStats(String id) => '/matches/$id/live';
  static String playerDetail(String id) => '/players/$id';
  static String editPlayer(String id) => '/players/$id/edit';
}

final appRouter = _createAppRouter();

GoRouter _createAppRouter() {
  final authNotifier = AuthRedirectNotifier(FirebaseAuth.instance);
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      if (!authNotifier.initialized) return null;
      final signedIn = authNotifier.user != null;
      final loggingIn = state.matchedLocation == AppRoutes.login;
      if (!signedIn) return loggingIn ? null : AppRoutes.login;
      final size = MediaQuery.maybeSizeOf(context);
      final wide = size == null || size.width >= ResponsiveLayout.tablet;
      if (loggingIn) return wide ? AppRoutes.dashboard : AppRoutes.ranking;
      if (!wide && state.matchedLocation == AppRoutes.dashboard) {
        return AppRoutes.ranking;
      }
      final permission = permissionForLocation(state.uri.toString());
      if (permission != null && !can(authNotifier.role, permission)) {
        return AppRoutes.ranking;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const UserProfileScreen(),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => NoTransitionPage(
          key: state.pageKey,
          child: HomeScreen(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
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
                path: AppRoutes.me,
                builder: (context, state) => const MyStatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'organization',
                    builder: (context, state) =>
                        const OrganizationManagementScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.events,
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class AuthRedirectNotifier extends ChangeNotifier {
  AuthRedirectNotifier(FirebaseAuth auth) {
    _subscription = auth.idTokenChanges().listen((user) async {
      _user = user;
      if (user == null) {
        _role = AppRole.member;
      } else {
        final token = await user.getIdTokenResult();
        _role = appRoleFromClaims(token.claims ?? const {});
      }
      _initialized = true;
      notifyListeners();
    });
  }

  User? get user => _user;
  AppRole get role => _role;
  bool get initialized => _initialized;

  User? _user;
  AppRole _role = AppRole.member;
  bool _initialized = false;
  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
