import 'package:go_router/go_router.dart';

import 'models/player.dart';
import 'models/scrimmage_match.dart';
import 'screens/home_screen.dart';
import 'screens/match_detail_screen.dart';
import 'screens/match_form_screen.dart';
import 'screens/player_detail_screen.dart';
import 'screens/player_form_screen.dart';
import 'screens/settings_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const ranking = '/ranking';
  static const matches = '/matches';
  static const players = '/players';
  static const settings = '/settings';
  static const newMatch = '/matches/new';
  static const newPlayer = '/players/new';

  static String matchDetail(String id) => '/matches/$id';
  static String editMatch(String id) => '/matches/$id/edit';
  static String playerDetail(String id) => '/players/$id';
  static String editPlayer(String id) => '/players/$id/edit';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.matches,
  routes: [
    GoRoute(path: '/', redirect: (_, _) => AppRoutes.matches),
    GoRoute(
      path: AppRoutes.ranking,
      builder: (context, state) =>
          const HomeScreen(section: HomeSection.ranking),
    ),
    GoRoute(
      path: AppRoutes.matches,
      builder: (context, state) =>
          const HomeScreen(section: HomeSection.matches),
    ),
    GoRoute(
      path: AppRoutes.players,
      builder: (context, state) =>
          const HomeScreen(section: HomeSection.players),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.newMatch,
      builder: (context, state) => const MatchFormScreen(),
    ),
    GoRoute(
      path: '/matches/:matchId',
      builder: (context, state) {
        return MatchDetailScreen(matchId: state.pathParameters['matchId']!);
      },
    ),
    GoRoute(
      path: '/matches/:matchId/edit',
      builder: (context, state) {
        return MatchFormScreen(
          matchId: state.pathParameters['matchId'],
          match: state.extra is ScrimmageMatch
              ? state.extra! as ScrimmageMatch
              : null,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.newPlayer,
      builder: (context, state) => const PlayerFormScreen(),
    ),
    GoRoute(
      path: '/players/:playerId',
      builder: (context, state) {
        return PlayerDetailScreen(playerId: state.pathParameters['playerId']!);
      },
    ),
    GoRoute(
      path: '/players/:playerId/edit',
      builder: (context, state) {
        return PlayerFormScreen(
          playerId: state.pathParameters['playerId'],
          player: state.extra is Player ? state.extra! as Player : null,
        );
      },
    ),
  ],
);
