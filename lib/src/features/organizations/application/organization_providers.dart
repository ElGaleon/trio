import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trio/src/features/auth/application/auth_service.dart';
import 'package:trio/src/features/organizations/domain/organization.dart';
import 'package:trio/src/shared/state_provider.dart';

final selectedOrganizationIdProvider = mutableProvider<String?>(() => null);

final organizationsProvider = StreamProvider<List<Organization>>((ref) {
  final user = ref.watch(authStateProvider).value;
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
