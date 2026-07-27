import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountProfileServiceProvider = Provider<AccountProfileService>((ref) {
  return AccountProfileService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

class AccountProfileDraft {
  const AccountProfileDraft({
    required this.firstName,
    required this.lastName,
    this.photoPath,
  });

  final String firstName;
  final String lastName;
  final String? photoPath;

  String get displayName => [
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');
}

class AccountProfileService {
  AccountProfileService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> saveProfile(
    AccountProfileDraft profile, {
    String? organizationId,
    String? playerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final displayName = profile.displayName;
    if (displayName.isNotEmpty || profile.photoPath != null) {
      await user.updateProfile(
        displayName: displayName.isEmpty ? null : displayName,
        photoURL: profile.photoPath,
      );
    }

    await _firestore.collection('users').doc(user.uid).set({
      'firstName': profile.firstName.trim(),
      'lastName': profile.lastName.trim(),
      'name': displayName,
      'email': user.email ?? '',
      'photoPath': _normalized(profile.photoPath),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (organizationId == null || playerId == null) return;
    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('players')
        .doc(playerId)
        .set({
          'firstName': profile.firstName.trim(),
          'lastName': profile.lastName.trim(),
          'email': user.email ?? '',
          'accountUserId': user.uid,
          if (_normalized(profile.photoPath) != null)
            'profileImagePath': _normalized(profile.photoPath),
        }, SetOptions(merge: true));
  }

  Future<void> linkCurrentUserToPlayer({
    required String organizationId,
    required String playerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('players')
        .doc(playerId)
        .set({
          'email': user.email ?? '',
          'accountUserId': user.uid,
        }, SetOptions(merge: true));
  }

  String? _normalized(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
