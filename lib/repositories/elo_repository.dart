import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/app_settings.dart';
import '../model/player.dart';
import '../model/scrimmage_match.dart';

class EloRepository {
  EloRepository({
    required List<ScrimmageMatch> matches,
    required this.settings,
    FirebaseFirestore? firestore,
  })  : matches = List.from(matches)..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final List<ScrimmageMatch> matches;
  final AppSettings settings;
  final FirebaseFirestore _firestore;

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
      return [settings.initialRating];
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
    final id = _firestore.collection('players').doc().id;
    await _firestore.collection('players').doc(id).set(
      Player(id: id, name: trimmed, rating: settings.initialRating).toMap(),
    );
  }

  Future<void> renamePlayer(Player player, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _firestore.collection('players').doc(player.id).update({'name': trimmed});
  }

  Future<void> savePlayer(
    Player player, {
    required String name,
    required PlayerLinePreference linePreference,
    required PlayerRole role,
    String? profileImagePath,
    required bool isExternal,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final updatedPlayer = Player(
      id: player.id,
      name: trimmed,
      linePreference: linePreference,
      role: role,
      profileImagePath: _normalizedImagePath(profileImagePath),
      isExternal: isExternal,
    );
    await _firestore.collection('players').doc(player.id).set(updatedPlayer.toMap());
  }

  Future<void> addPlayerWithLine(
    String name,
    PlayerLinePreference linePreference,
    PlayerRole role, [
    String? profileImagePath,
    bool isExternal = false,
  ]) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = _firestore.collection('players').doc().id;
    final player = Player(
      id: id,
      name: trimmed,
      rating: settings.initialRating,
      linePreference: linePreference,
      role: role,
      profileImagePath: _normalizedImagePath(profileImagePath),
      isExternal: isExternal,
    );
    await _firestore.collection('players').doc(id).set(player.toMap());
  }

  Future<void> deletePlayer(String playerId) async {
    final matchesSnap = await _firestore.collection('matches').get();
    for (final doc in matchesSnap.docs) {
      final matchMap = doc.data();
      final teamAIds = List<String>.from(matchMap['teamAIds'] as List? ?? []);
      final teamBIds = List<String>.from(matchMap['teamBIds'] as List? ?? []);
      if (teamAIds.contains(playerId) || teamBIds.contains(playerId)) {
        await doc.reference.delete();
      }
    }
    await _firestore.collection('players').doc(playerId).delete();
  }

  ScrimmageMatch? getMatch(String id) {
    for (final match in matches) {
      if (match.id == id) return match;
    }
    return null;
  }

  Future<void> upsertMatch(ScrimmageMatch match) async {
    await _firestore.collection('matches').doc(match.id).set(match.toMap());
  }

  Future<void> deleteMatch(String matchId) async {
    await _firestore.collection('matches').doc(matchId).delete();
  }

  Future<void> recalculateRatings() async {
    return;
  }

  String? _normalizedImagePath(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
