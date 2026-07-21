import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/features/players/domain/player_role.dart';
import 'package:trio/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:trio/src/features/settings/domain/app_settings.dart';
import 'package:trio/src/shared/state_provider.dart';

final appSettingsProvider = Provider<AppSettings>((ref) {
  return ref.watch(firebaseSettingsProvider).value ?? AppSettings();
});

final rankedPlayersProvider = Provider<List<Player>>((ref) {
  return ref.watch(firebasePlayersProvider).value ?? const [];
});

final playersSearchQueryProvider = mutableProvider<String>(() => '');

final playersRoleFilterProvider = mutableProvider<PlayerRole?>(() => null);

final playersLineFilterProvider = mutableProvider<PlayerLinePreference?>(
  () => null,
);

final filteredPlayersProvider = Provider<List<Player>>((ref) {
  return _filterPlayers(
    ref.watch(rankedPlayersProvider),
    ref.watch(playersSearchQueryProvider),
    ref.watch(playersRoleFilterProvider),
    ref.watch(playersLineFilterProvider),
  );
});

final rankingRoleFilterProvider = mutableProvider<PlayerRole?>(() => null);

final rankingLineFilterProvider = mutableProvider<PlayerLinePreference?>(
  () => null,
);

final filteredRankingPlayersProvider = Provider<List<Player>>((ref) {
  return _filterPlayers(
    ref.watch(rankedPlayersProvider),
    '',
    ref.watch(rankingRoleFilterProvider),
    ref.watch(rankingLineFilterProvider),
  );
});

List<Player> _filterPlayers(
  List<Player> players,
  String query,
  PlayerRole? role,
  PlayerLinePreference? line,
) {
  final normalizedQuery = query.trim().toLowerCase();
  return players.where((player) {
    final matchesName =
        normalizedQuery.isEmpty ||
        player.name.toLowerCase().contains(normalizedQuery);
    final matchesRole = role == null || player.role == role;
    final matchesLine = line == null || player.linePreference == line;
    return matchesName && matchesRole && matchesLine;
  }).toList();
}
