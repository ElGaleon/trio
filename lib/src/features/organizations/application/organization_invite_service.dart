import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skrim/src/features/auth/application/account_profile_service.dart';
import 'package:skrim/src/features/auth/application/auth_service.dart';
import 'package:skrim/src/features/organizations/application/organization_providers.dart';

final organizationInviteServiceProvider = Provider<OrganizationInviteService>((
  ref,
) {
  return OrganizationInviteService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    accountProfileService: ref.watch(accountProfileServiceProvider),
    ref: ref,
  );
});

final pendingOrganizationInvitesProvider =
    StreamProvider<List<OrganizationInvite>>((ref) {
      final authState = ref.watch(authStateProvider);
      final user = FirebaseAuth.instance.currentUser ?? authState.value;
      final normalizedEmail = OrganizationInviteService.normalizeEmail(
        user?.email,
      );
      if (normalizedEmail == null) return Stream.value(const []);

      return FirebaseFirestore.instance
          .collection('userInvites')
          .doc(normalizedEmail)
          .collection('items')
          .snapshots()
          .map((snapshot) {
            final invites = snapshot.docs
                .map((doc) => OrganizationInvite.fromDocument(doc))
                .toList();
            return invites..sort(
              (a, b) => a.organizationName.compareTo(b.organizationName),
            );
          });
    });

final playerPendingInviteProvider =
    StreamProvider.family<OrganizationInvite?, String>((ref, playerId) {
      final organizationId = ref.watch(activeOrganizationIdProvider);
      if (organizationId == null || playerId.trim().isEmpty) {
        return Stream.value(null);
      }

      return FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('invites')
          .where('playerId', isEqualTo: playerId)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return null;
            return OrganizationInvite.fromDocument(snapshot.docs.first);
          });
    });

class OrganizationInvite {
  const OrganizationInvite({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.email,
    required this.playerId,
    required this.expiresAt,
  });

  final String id;
  final String organizationId;
  final String organizationName;
  final String email;
  final String playerId;
  final DateTime? expiresAt;

  bool get isExpired {
    final expiry = expiresAt;
    return expiry == null || expiry.isBefore(DateTime.now());
  }

  static OrganizationInvite fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return OrganizationInvite(
      id: doc.id,
      organizationId: data['organizationId'] as String? ?? '',
      organizationName: data['organizationName'] as String? ?? 'Squadra',
      email: data['email'] as String? ?? doc.id,
      playerId: data['playerId'] as String? ?? '',
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}

class OrganizationInviteService {
  OrganizationInviteService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required AccountProfileService accountProfileService,
    required Ref ref,
  }) : _firestore = firestore,
       _auth = auth,
       _accountProfileService = accountProfileService,
       _ref = ref;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AccountProfileService _accountProfileService;
  final Ref _ref;

  Future<void> invitePlayer({
    required String organizationId,
    required String playerId,
    required String email,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final orgRef = _firestore.collection('organizations').doc(organizationId);
    final org = await orgRef.get();
    final orgData = org.data();
    if (orgData == null || orgData['ownerId'] != user.uid) {
      throw StateError('Solo il proprietario può invitare giocatori.');
    }

    final expiresAt = DateTime.now().add(const Duration(days: 7));
    final data = {
      'email': normalizedEmail,
      'authEmails': [normalizedEmail, email.trim()],
      'playerId': playerId,
      'organizationId': organizationId,
      'organizationName': orgData['name'] as String? ?? 'Squadra',
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
    final batch = _firestore.batch();
    batch.set(_inviteRef(organizationId, normalizedEmail), data);
    batch.set(_userInviteRef(organizationId, normalizedEmail), data);
    await batch.commit();
  }

  Future<void> acceptInvite({
    required OrganizationInvite invite,
    AccountProfileDraft? profile,
  }) async {
    final user = _auth.currentUser;
    final normalizedEmail = normalizeEmail(invite.email);
    if (user == null || normalizedEmail == null) {
      throw StateError('Accedi con la mail invitata per accettare l\'invito.');
    }
    if (_normalizeEmail(user.email) != normalizedEmail) {
      throw StateError('Questo invito è valido solo per $normalizedEmail.');
    }

    final inviteRef = _inviteRef(invite.organizationId, normalizedEmail);
    final inviteSnapshot = await inviteRef.get();
    final data = inviteSnapshot.data();
    if (data == null) throw StateError('Invito non trovato.');
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    final playerId = data['playerId'] as String?;
    if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
      await _deleteInvite(invite.organizationId, normalizedEmail);
      throw StateError('Invito scaduto. Chiedi un nuovo invito.');
    }

    final orgRef = _firestore
        .collection('organizations')
        .doc(invite.organizationId);
    await orgRef.set({
      'members': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (profile != null) {
      await _accountProfileService.saveProfile(
        profile,
        organizationId: invite.organizationId,
        playerId: playerId,
      );
    } else if (playerId != null && playerId.isNotEmpty) {
      await _accountProfileService.linkCurrentUserToPlayer(
        organizationId: invite.organizationId,
        playerId: playerId,
      );
    }
    await _deleteInvite(invite.organizationId, normalizedEmail);
    _ref
        .read(selectedOrganizationIdProvider.notifier)
        .set(invite.organizationId);
    _ref.invalidate(organizationsProvider);
    _ref.invalidate(pendingOrganizationInvitesProvider);
  }

  Future<void> discardInvite(OrganizationInvite invite) async {
    final normalizedEmail = normalizeEmail(invite.email);
    if (normalizedEmail == null) return;
    await _deleteInvite(invite.organizationId, normalizedEmail);
    _ref.invalidate(pendingOrganizationInvitesProvider);
  }

  Future<void> revokeInvite({
    required String organizationId,
    required String email,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    if (normalizedEmail == null) return;
    await _deleteInvite(organizationId, normalizedEmail);
  }

  Future<void> _deleteInvite(String organizationId, String email) async {
    final batch = _firestore.batch();
    batch.delete(_inviteRef(organizationId, email));
    batch.delete(_userInviteRef(organizationId, email));
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _inviteRef(
    String organizationId,
    String email,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('invites')
        .doc(email);
  }

  DocumentReference<Map<String, dynamic>> _userInviteRef(
    String organizationId,
    String email,
  ) {
    return _firestore
        .collection('userInvites')
        .doc(email)
        .collection('items')
        .doc(organizationId);
  }

  static String? normalizeEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String? _normalizeEmail(String? email) => normalizeEmail(email);
}
