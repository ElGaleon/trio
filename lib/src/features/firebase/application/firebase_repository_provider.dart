import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skrim/src/features/auth/application/auth_service.dart';
import 'package:skrim/src/features/events/domain/team_event.dart';
import 'package:skrim/src/features/firebase/data/firestore_skrim_repository.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/organizations/application/organization_providers.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/settings/domain/app_settings.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firestoreSkrimRepositoryProvider = Provider<FirestoreSkrimRepository?>((
  ref,
) {
  ref.watch(authStateProvider);
  final organizationId = ref.watch(activeOrganizationIdProvider);
  if (FirebaseAuth.instance.currentUser == null || organizationId == null) {
    return null;
  }
  return FirestoreSkrimRepository(
    firestore: ref.watch(firestoreProvider),
    organizationId: organizationId,
  );
});

final firebasePlayersProvider = StreamProvider<List<Player>>((ref) {
  final repository = ref.watch(firestoreSkrimRepositoryProvider);
  return repository?.watchPlayers() ?? Stream.value(const []);
});

final firebaseMatchesProvider = StreamProvider<List<ScrimmageMatch>>((ref) {
  final repository = ref.watch(firestoreSkrimRepositoryProvider);
  return repository?.watchMatches() ?? Stream.value(const []);
});

final firebaseMatchProvider = StreamProvider.family<ScrimmageMatch?, String>((
  ref,
  matchId,
) {
  final repository = ref.watch(firestoreSkrimRepositoryProvider);
  return repository?.watchMatch(matchId) ?? Stream.value(null);
});

final firebaseEventsProvider = StreamProvider<List<TeamEvent>>((ref) {
  final repository = ref.watch(firestoreSkrimRepositoryProvider);
  return repository?.watchEvents() ?? Stream.value(const []);
});

final firebaseSettingsProvider = StreamProvider<AppSettings>((ref) {
  final repository = ref.watch(firestoreSkrimRepositoryProvider);
  return repository?.watchSettings() ?? Stream.value(AppSettings());
});
