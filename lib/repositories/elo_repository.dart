import 'dart:math';

import 'package:hive/hive.dart';

import '../model/app_settings.dart';
import '../model/player.dart';
import '../model/scrimmage_match.dart';

class EloRepository {
  EloRepository(this.playersBox, this.matchesBox, this.settings);

  final Box<Player> playersBox;
  final Box<ScrimmageMatch> matchesBox;
  final AppSettings settings;

  List<Player> get rankedPlayers {
    return playersBox.values.toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  List<Player> get players {
    return playersBox.values.toList()..sort((a, b) => b.name.compareTo(a.name));
  }

  List<ScrimmageMatch> get matches {
    return matchesBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<ScrimmageMatch> matchesForPlayer(String playerId) {
    return matches
        .where(
          (match) =>
              match.teamAIds.contains(playerId) ||
              match.teamBIds.contains(playerId),
        )
        .toList();
  }

  List<double> ratingHistoryForPlayer(String playerId) {
    final orderedMatches = matchesForPlayer(playerId).reversed.toList();
    if (orderedMatches.isEmpty) {
      return [playersBox.get(playerId)?.rating ?? settings.initialRating];
    }

    final history = <double>[
      orderedMatches.first.initialRatings[playerId] ?? settings.initialRating,
    ];
    for (final match in orderedMatches) {
      history.add(match.finalRatings[playerId] ?? history.last);
    }
    return history;
  }

  Future<void> addPlayer(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await playersBox.put(
      id,
      Player(id: id, name: trimmed, rating: settings.initialRating),
    );
  }

  Future<void> renamePlayer(Player player, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    player.name = trimmed;
    await playersBox.put(player.id, player);
  }

  Future<void> savePlayer(
    Player player, {
    required String name,
    required PlayerLinePreference? linePreference,
    required PlayerRole role,
    String? profileImagePath,
    required bool isExternal,
    int? jerseyNumber,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    player
      ..name = trimmed
      ..linePreference = linePreference
      ..role = role
      ..profileImagePath = _normalizedImagePath(profileImagePath)
      ..isExternal = isExternal
      ..jerseyNumber = jerseyNumber;
    await playersBox.put(player.id, player);
  }

  Future<void> addPlayerWithLine(
    String name,
    PlayerLinePreference? linePreference,
    PlayerRole role, [
    String? profileImagePath,
    bool isExternal = false,
    int? jerseyNumber,
  ]) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await playersBox.put(
      id,
      Player(
        id: id,
        name: trimmed,
        rating: settings.initialRating,
        linePreference: linePreference,
        role: role,
        profileImagePath: _normalizedImagePath(profileImagePath),
        isExternal: isExternal,
        jerseyNumber: jerseyNumber,
      ),
    );
  }

  Future<void> deletePlayer(String playerId) async {
    for (final match in matchesBox.values.toList()) {
      if (match.teamAIds.contains(playerId) ||
          match.teamBIds.contains(playerId)) {
        await matchesBox.delete(match.id);
      }
    }
    await playersBox.delete(playerId);
    await recalculateRatings();
  }

  ScrimmageMatch? getMatch(String id) {
    return matchesBox.get(id);
  }

  Future<void> upsertMatch(ScrimmageMatch match) async {
    await matchesBox.put(match.id, match);
    await recalculateRatings();
  }

  Future<void> deleteMatch(String matchId) async {
    await matchesBox.delete(matchId);
    await recalculateRatings();
  }

  Future<void> recalculateRatings() async {
    final players = {
      for (final player in playersBox.values)
        player.id: Player(
          id: player.id,
          name: player.name,
          rating: settings.initialRating,
          linePreference: player.linePreference,
          role: player.role,
          profileImagePath: player.profileImagePath,
          isExternal: player.isExternal,
          jerseyNumber: player.jerseyNumber,
        ),
    };
    final orderedMatches = matchesBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final match in orderedMatches) {
      final rosterA = match.teamARosterIds.isNotEmpty ? match.teamARosterIds : match.teamAIds;
      final rosterB = match.teamBRosterIds.isNotEmpty ? match.teamBRosterIds : match.teamBIds;
      final teamA = rosterA.map((id) => players[id]).nonNulls.toList();
      final teamB = rosterB.map((id) => players[id]).nonNulls.toList();
      if (teamA.isEmpty ||
          teamB.isEmpty ||
          teamA.length < match.teamSize ||
          teamB.length < match.teamSize) {
        continue;
      }

      final allPlayers = [...teamA, ...teamB];
      final initialRatings = {
        for (final player in allPlayers) player.id: player.rating,
      };
      final ratingA =
          teamA.map((player) => player.rating).reduce((a, b) => a + b) /
          teamA.length;
      final ratingB =
          teamB.map((player) => player.rating).reduce((a, b) => a + b) /
          teamB.length;
      final expectedA = 1 / (1 + pow(10, (ratingB - ratingA) / 400));
      final expectedB = 1 - expectedA;
      final actualA = match.isDraw ? 0.5 : (match.teamAWon ? 1.0 : 0.0);
      final actualB = match.isDraw ? 0.5 : 1 - actualA;
      final deltaA = settings.eloKFactor * (actualA - expectedA);
      final deltaB = settings.eloKFactor * (actualB - expectedB);

      for (final player in teamA) {
        player
          ..rating += deltaA
          ..matchesPlayed += 1;
        if (!match.isDraw) {
          match.teamAWon ? player.wins += 1 : player.losses += 1;
        }
      }
      for (final player in teamB) {
        player
          ..rating += deltaB
          ..matchesPlayed += 1;
        if (!match.isDraw) {
          match.teamAWon ? player.losses += 1 : player.wins += 1;
        }
      }

      match
        ..initialRatings = initialRatings
        ..finalRatings = {
          for (final player in allPlayers) player.id: player.rating,
        };
      await matchesBox.put(match.id, match);
    }

    for (final player in players.values) {
      await playersBox.put(player.id, player);
    }
  }

  String? _normalizedImagePath(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
