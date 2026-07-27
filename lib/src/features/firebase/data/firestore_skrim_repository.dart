import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:skrim/src/features/events/domain/team_event.dart';
import 'package:skrim/src/features/firebase/data/firestore_paths.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/players/domain/player_line_preference.dart';
import 'package:skrim/src/features/players/domain/player_role.dart';
import 'package:skrim/src/features/settings/domain/app_settings.dart';

class FirestoreSkrimRepository {
  FirestoreSkrimRepository({
    required FirebaseFirestore firestore,
    required String organizationId,
  }) : _firestore = firestore,
       _organizationId = organizationId;

  final FirebaseFirestore _firestore;
  final String _organizationId;

  CollectionReference<Map<String, dynamic>> get _players =>
      _firestore.collection(FirestorePaths.players(_organizationId));

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection(FirestorePaths.matches(_organizationId));

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection(FirestorePaths.events(_organizationId));

  DocumentReference<Map<String, dynamic>> get _settings =>
      _firestore.doc(FirestorePaths.settings(_organizationId));

  Stream<List<Player>> watchPlayers() {
    return _players.snapshots().map((snapshot) {
      final players = snapshot.docs.where((doc) => doc.id != '_meta').map((
        doc,
      ) {
        return Player.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
      return players..sort((a, b) => b.rating.compareTo(a.rating));
    });
  }

  Stream<List<ScrimmageMatch>> watchMatches() {
    return _matches.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.where((doc) => doc.id != '_meta').map((doc) {
        return ScrimmageMatch.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    });
  }

  Stream<ScrimmageMatch?> watchMatch(String id) {
    return _matches.doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return ScrimmageMatch.fromMap({'id': doc.id, ...data});
    });
  }

  Stream<List<TeamEvent>> watchEvents() {
    return _events.orderBy('startAt').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) => doc.id != '_meta').map((doc) {
        return TeamEvent.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    });
  }

  Stream<AppSettings> watchSettings() {
    return _settings.snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return AppSettings();
      return AppSettings.fromGlobalMap(data);
    });
  }

  Future<void> ensureSettings() async {
    final doc = await _settings.get();
    if (!doc.exists) {
      await _settings.set(AppSettings().toGlobalMap());
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settings.set(settings.toGlobalMap(), SetOptions(merge: true));
    await recalculateRatings(settings);
  }

  Future<String> addPlayerWithLine(
    String name, {
    String firstName = '',
    String lastName = '',
    String email = '',
    required PlayerLinePreference? linePreference,
    required PlayerRole role,
    String? profileImagePath,
    bool isExternal = false,
    int? jerseyNumber,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final doc = _players.doc();
    await doc.set(
      Player(
        id: doc.id,
        name: trimmed,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        linePreference: linePreference,
        role: role,
        profileImagePath: _normalizedImagePath(profileImagePath),
        isExternal: isExternal,
        jerseyNumber: jerseyNumber,
      ).toMap(),
    );
    return doc.id;
  }

  Future<void> savePlayer(
    Player player, {
    required String name,
    String firstName = '',
    String lastName = '',
    String email = '',
    required PlayerLinePreference? linePreference,
    required PlayerRole role,
    String? profileImagePath,
    required bool isExternal,
    int? jerseyNumber,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _players
        .doc(player.id)
        .set(
          Player(
            id: player.id,
            name: trimmed,
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: email.trim(),
            rating: player.rating,
            matchesPlayed: player.matchesPlayed,
            wins: player.wins,
            losses: player.losses,
            linePreference: linePreference,
            role: role,
            profileImagePath: _normalizedImagePath(profileImagePath),
            accountUserId: player.accountUserId,
            isExternal: isExternal,
            jerseyNumber: jerseyNumber,
          ).toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deletePlayer(String playerId) async {
    final batch = _firestore.batch();
    batch.delete(_players.doc(playerId));
    final matches = await _matches
        .where('presentPlayerIds', arrayContains: playerId)
        .get();
    for (final match in matches.docs) {
      batch.delete(match.reference);
    }
    await batch.commit();
    await recalculateRatings(await _loadSettings());
  }

  Future<void> upsertMatch(ScrimmageMatch match) async {
    await _matches.doc(match.id).set(match.toMap());
    await recalculateRatings(await _loadSettings());
  }

  Future<void> deleteMatch(String matchId) async {
    await _matches.doc(matchId).delete();
    await recalculateRatings(await _loadSettings());
  }

  Future<String> addEvent(TeamEvent event) async {
    final doc = _events.doc();
    await doc.set(event.copyWith(id: doc.id).toMap());
    return doc.id;
  }

  Future<void> saveEvent(TeamEvent event) async {
    await _events.doc(event.id).set(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _events.doc(eventId).delete();
  }

  Future<void> linkMatchToEvent(String eventId, String matchId) async {
    await _events.doc(eventId).set({
      'matchIds': FieldValue.arrayUnion([matchId]),
    }, SetOptions(merge: true));
  }

  Future<ScrimmageMatch> updateMatchTransaction(
    String matchId,
    ScrimmageMatch Function(ScrimmageMatch match) update,
  ) async {
    return _firestore.runTransaction((transaction) async {
      final ref = _matches.doc(matchId);
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) {
        throw StateError('Partita non trovata: $matchId');
      }
      final current = ScrimmageMatch.fromMap({'id': snapshot.id, ...data});
      final next = update(current);
      transaction.set(ref, next.toMap());
      return next;
    });
  }

  Future<void> recalculateRatings(AppSettings settings) async {
    final playersSnapshot = await _players.get();
    final matchesSnapshot = await _matches.get();
    final players = {
      for (final doc in playersSnapshot.docs.where((doc) => doc.id != '_meta'))
        doc.id: Player.fromMap({'id': doc.id, ...doc.data()}),
    };
    final orderedMatches =
        matchesSnapshot.docs
            .where((doc) => doc.id != '_meta')
            .map((doc) => ScrimmageMatch.fromMap({'id': doc.id, ...doc.data()}))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final recalculatedPlayers = {
      for (final player in players.values)
        player.id: Player(
          id: player.id,
          name: player.name,
          firstName: player.firstName,
          lastName: player.lastName,
          email: player.email,
          rating: settings.initialRating,
          linePreference: player.linePreference,
          role: player.role,
          profileImagePath: player.profileImagePath,
          accountUserId: player.accountUserId,
          isExternal: player.isExternal,
          jerseyNumber: player.jerseyNumber,
        ),
    };

    final updatedMatches = <ScrimmageMatch>[];
    for (final match in orderedMatches) {
      final rosterA = match.teamARosterIds.isNotEmpty
          ? match.teamARosterIds
          : match.teamAIds;
      final rosterB = match.teamBRosterIds.isNotEmpty
          ? match.teamBRosterIds
          : match.teamBIds;
      final teamA = rosterA
          .map((id) => recalculatedPlayers[id])
          .nonNulls
          .toList();
      final teamB = rosterB
          .map((id) => recalculatedPlayers[id])
          .nonNulls
          .toList();
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
      final actualA = match.isDraw ? 0.5 : (match.teamAWon ? 1.0 : 0.0);
      final deltaA = settings.eloKFactor * (actualA - expectedA);
      final deltaB = settings.eloKFactor * ((1 - actualA) - (1 - expectedA));

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
      updatedMatches.add(match);
    }

    final batch = _firestore.batch();
    for (final player in recalculatedPlayers.values) {
      batch.set(
        _players.doc(player.id),
        player.toMap(),
        SetOptions(merge: true),
      );
    }
    for (final match in updatedMatches) {
      batch.set(_matches.doc(match.id), match.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<AppSettings> _loadSettings() async {
    final doc = await _settings.get();
    final data = doc.data();
    return data == null ? AppSettings() : AppSettings.fromGlobalMap(data);
  }

  String? _normalizedImagePath(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
