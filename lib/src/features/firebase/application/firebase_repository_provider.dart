import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trio/src/features/auth/application/auth_service.dart';
import 'package:trio/src/features/events/domain/team_event.dart';
import 'package:trio/src/features/firebase/data/firestore_trio_repository.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/organizations/application/organization_providers.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/settings/domain/app_settings.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firestoreTrioRepositoryProvider = Provider<FirestoreTrioRepository?>((
  ref,
) {
  ref.watch(authStateProvider);
  final organizationId = ref.watch(activeOrganizationIdProvider);
  if (FirebaseAuth.instance.currentUser == null || organizationId == null) {
    return null;
  }
  return FirestoreTrioRepository(
    firestore: ref.watch(firestoreProvider),
    organizationId: organizationId,
  );
});

final firebasePlayersProvider = StreamProvider<List<Player>>((ref) {
  final repository = ref.watch(firestoreTrioRepositoryProvider);
  return repository?.watchPlayers() ?? Stream.value(const []);
});

final firebaseMatchesProvider = StreamProvider<List<ScrimmageMatch>>((ref) {
  final repository = ref.watch(firestoreTrioRepositoryProvider);
  return repository?.watchMatches() ?? Stream.value(const []);
});

final firebaseMatchProvider = StreamProvider.family<ScrimmageMatch?, String>((
  ref,
  matchId,
) {
  final repository = ref.watch(firestoreTrioRepositoryProvider);
  return repository?.watchMatch(matchId) ?? Stream.value(null);
});

final firebaseEventsProvider = StreamProvider<List<TeamEvent>>((ref) {
  final repository = ref.watch(firestoreTrioRepositoryProvider);
  return repository?.watchEvents() ?? Stream.value(const []);
});

final firebaseSettingsProvider = StreamProvider<AppSettings>((ref) {
  final repository = ref.watch(firestoreTrioRepositoryProvider);
  return repository?.watchSettings() ?? Stream.value(AppSettings());
});
