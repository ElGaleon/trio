import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skrim/src/features/auth/application/auth_service.dart';
import 'package:skrim/src/features/firebase/data/firestore_paths.dart';
import 'package:skrim/src/features/organizations/domain/organization.dart';

const _lastOrganizationIdKey = 'lastOrganizationId';

final selectedOrganizationIdProvider =
    NotifierProvider<SelectedOrganizationIdNotifier, String?>(
      SelectedOrganizationIdNotifier.new,
    );

class SelectedOrganizationIdNotifier extends Notifier<String?> {
  bool _changedLocally = false;

  @override
  String? build() {
    unawaited(_load());
    return null;
  }

  void set(String? value) {
    _changedLocally = true;
    state = value;
    unawaited(_save(value));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastOrganizationIdKey);
    if (!ref.mounted) return;
    if (!_changedLocally && value != null && value.isNotEmpty) state = value;
  }

  Future<void> _save(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await prefs.remove(_lastOrganizationIdKey);
    } else {
      await prefs.setString(_lastOrganizationIdKey, trimmed);
    }
  }
}

final organizationsProvider = StreamProvider<List<Organization>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = FirebaseAuth.instance.currentUser ?? authState.value;
  if (user == null) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collection('organizations')
      .where('members', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
        final organizations = snapshot.docs.map((doc) {
          return Organization.fromMap({'id': doc.id, ...doc.data()});
        }).toList();
        return organizations..sort((a, b) => a.name.compareTo(b.name));
      });
});

final activeOrganizationProvider = Provider<Organization?>((ref) {
  final organizations = ref.watch(organizationsProvider).value ?? const [];
  final selectedId = ref.watch(selectedOrganizationIdProvider);
  return selectOrganization(organizations, selectedId);
});

final activeOrganizationIdProvider = Provider<String?>((ref) {
  return ref.watch(activeOrganizationProvider)?.id;
});

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  return OrganizationService(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class OrganizationService {
  OrganizationService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> createOrganization(String name, {String? logoUrl}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final user = await _requireUser();

    final batch = _firestore.batch();
    final orgRef = _firestore.collection('organizations').doc();
    final userRef = _firestore.collection('users').doc(user.uid);

    batch.set(
      orgRef,
      Organization(
        id: orgRef.id,
        name: trimmed,
        ownerId: user.uid,
        members: [user.uid],
        logoUrl: _normalized(logoUrl),
      ).toMap()..['createdAt'] = FieldValue.serverTimestamp(),
    );
    batch.set(userRef, {
      'email': user.email ?? '',
      'name': user.displayName ?? user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return orgRef.id;
  }

  Future<void> updateLogo(String organizationId, String? logoUrl) async {
    await updateOrganization(organizationId, logoUrl: logoUrl);
  }

  Future<void> updateOrganization(
    String organizationId, {
    String? name,
    String? logoUrl,
  }) async {
    final user = await _requireUser();
    final ref = _firestore.collection('organizations').doc(organizationId);
    final snapshot = await ref.get();
    if (snapshot.data()?['ownerId'] != user.uid) {
      throw StateError('Solo il creatore può modificare la squadra.');
    }
    final data = <String, Object?>{'updatedAt': FieldValue.serverTimestamp()};
    final normalizedName = _normalized(name);
    if (normalizedName != null) data['name'] = normalizedName;
    data['logoUrl'] = _normalized(logoUrl);
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> deleteOrganization(String organizationId) async {
    final user = await _requireUser();
    final orgRef = _firestore.collection('organizations').doc(organizationId);
    final snapshot = await orgRef.get();
    if (snapshot.data()?['ownerId'] != user.uid) {
      throw StateError('Solo il creatore può eliminare la squadra.');
    }

    final inviteDocs = await orgRef.collection('invites').get();
    await _deleteDocuments([
      ...inviteDocs.docs.map((doc) => doc.reference),
      for (final doc in inviteDocs.docs)
        _firestore
            .collection('userInvites')
            .doc((doc.data()['email'] as String? ?? doc.id).trim())
            .collection('items')
            .doc(organizationId),
      ...(await _firestore
              .collection(FirestorePaths.players(organizationId))
              .get())
          .docs
          .map((doc) => doc.reference),
      ...(await _firestore
              .collection(FirestorePaths.matches(organizationId))
              .get())
          .docs
          .map((doc) => doc.reference),
      ...(await _firestore
              .collection(FirestorePaths.events(organizationId))
              .get())
          .docs
          .map((doc) => doc.reference),
      ...(await orgRef.collection('settings').get()).docs.map(
        (doc) => doc.reference,
      ),
      orgRef,
    ]);
  }

  Future<void> _deleteDocuments(
    Iterable<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    var batch = _firestore.batch();
    var count = 0;
    for (final ref in refs) {
      batch.delete(ref);
      count++;
      if (count == 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  Future<User> _requireUser() async {
    final current = _auth.currentUser;
    if (current != null) return current;
    return _auth
        .authStateChanges()
        .where((user) => user != null)
        .cast<User>()
        .first
        .timeout(const Duration(seconds: 8));
  }

  String? _normalized(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

Organization? selectOrganization(
  List<Organization> organizations,
  String? selectedId,
) {
  if (organizations.length == 1) return organizations.first;
  return organizations
      .where((organization) => organization.id == selectedId)
      .firstOrNull;
}
