import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:skrim/src/features/auth/application/rbac_provider.dart';
import 'package:skrim/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:skrim/src/features/organizations/application/organization_invite_service.dart';
import 'package:skrim/src/features/organizations/application/organization_providers.dart';
import 'package:skrim/src/features/players/domain/player_line_preference.dart';
import 'package:skrim/src/features/players/domain/player_role.dart';
import 'package:skrim/src/features/players/domain/player_form_state.dart';
import 'player_providers.dart';

class PlayerFormNotifier extends Notifier<PlayerFormState> {
  final String? arg;
  PlayerFormNotifier(this.arg);

  @override
  PlayerFormState build() {
    if (arg == null) {
      return PlayerFormState(
        name: '',
        firstName: '',
        lastName: '',
        email: '',
        linePreference: null,
        role: PlayerRole.cutter,
        isExternal: false,
        jerseyNumber: '',
        profileImagePath: null,
      );
    }

    final player = ref
        .read(rankedPlayersProvider)
        .where((player) => player.id == arg)
        .firstOrNull;
    if (player == null) {
      return PlayerFormState(
        name: '',
        firstName: '',
        lastName: '',
        email: '',
        linePreference: null,
        role: PlayerRole.cutter,
        isExternal: false,
        jerseyNumber: '',
        profileImagePath: null,
      );
    }

    return PlayerFormState(
      name: player.name,
      firstName: player.firstName,
      lastName: player.lastName,
      email: player.email,
      linePreference: player.linePreference,
      role: player.role,
      isExternal: player.isExternal,
      jerseyNumber: player.jerseyNumber?.toString() ?? '',
      profileImagePath: player.profileImagePath,
    );
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateFirstName(String value) {
    state = state.copyWith(firstName: value);
  }

  void updateLastName(String value) {
    state = state.copyWith(lastName: value);
  }

  void updateEmail(String value) {
    state = state.copyWith(email: value);
  }

  void updateJerseyNumber(String value) {
    state = state.copyWith(jerseyNumber: value);
  }

  void updateLinePreference(PlayerLinePreference? line) {
    state = state.copyWith(linePreference: line);
  }

  void updateRole(PlayerRole role) {
    state = state.copyWith(role: role);
  }

  void toggleIsExternal() {
    state = state.copyWith(isExternal: !state.isExternal);
  }

  void removeImage() {
    state = state.copyWith(nullifyProfileImagePath: true);
  }

  Future<bool> pickImageFromGallery() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 86,
      );
      if (image == null) return false;
      final savedPath = await _persistImage(File(image.path));
      state = state.copyWith(profileImagePath: savedPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pickImageFromCamera() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1400,
        imageQuality: 86,
      );
      if (image == null) return false;
      final savedPath = await _persistImage(File(image.path));
      state = state.copyWith(profileImagePath: savedPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pickImageFromFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );
      final path = result?.files.single.path;
      if (path == null || path.trim().isEmpty) return false;
      final savedPath = await _persistImage(File(path));
      state = state.copyWith(profileImagePath: savedPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _persistImage(File source) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${directory.path}/player_images');
    if (!imagesDirectory.existsSync()) {
      imagesDirectory.createSync(recursive: true);
    }
    final extension = _imageExtension(source.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = File('${imagesDirectory.path}/$fileName');
    final copiedFile = await source.copy(destination.path);
    return copiedFile.path;
  }

  String _imageExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.jpg';
    return path.substring(dot).toLowerCase();
  }

  Future<bool> save(String? playerId) async {
    final role = ref.read(currentRoleProvider);
    final permission = playerId == null
        ? AppPermission.createPlayer
        : AppPermission.editPlayer;
    if (!can(role, permission)) return false;
    final repository = ref.read(firestoreSkrimRepositoryProvider);
    if (repository == null) {
      throw StateError(
        'Seleziona o crea un workspace prima di salvare giocatori.',
      );
    }
    if (playerId == null) {
      final savedPlayerId = await repository.addPlayerWithLine(
        state.name,
        firstName: state.firstName,
        lastName: state.lastName,
        email: state.email,
        linePreference: state.linePreference,
        role: state.role,
        profileImagePath: state.profileImagePath,
        isExternal: state.isExternal,
        jerseyNumber: _jerseyNumberOrNull(),
      );
      await _inviteByEmail(savedPlayerId, previousEmail: '');
      return true;
    }

    final player = ref
        .read(rankedPlayersProvider)
        .where((player) => player.id == playerId)
        .firstOrNull;
    if (player != null) {
      await repository.savePlayer(
        player,
        name: state.name,
        firstName: state.firstName,
        lastName: state.lastName,
        email: state.email,
        linePreference: state.linePreference,
        role: state.role,
        profileImagePath: state.profileImagePath,
        isExternal: state.isExternal,
        jerseyNumber: _jerseyNumberOrNull(),
      );
      await _inviteByEmail(player.id, previousEmail: player.email);
      return true;
    }
    return false;
  }

  Future<void> _inviteByEmail(
    String playerId, {
    required String previousEmail,
  }) async {
    final organizationId = ref.read(activeOrganizationIdProvider);
    final email = state.email.trim();
    if (organizationId == null || playerId.isEmpty) return;
    if (email.toLowerCase() == previousEmail.trim().toLowerCase()) return;
    final inviteService = ref.read(organizationInviteServiceProvider);
    if (previousEmail.trim().isNotEmpty) {
      await inviteService.revokeInvite(
        organizationId: organizationId,
        email: previousEmail,
      );
    }
    if (email.isEmpty) return;
    await inviteService.invitePlayer(
      organizationId: organizationId,
      playerId: playerId,
      email: email,
    );
  }

  int? _jerseyNumberOrNull() {
    final trimmed = state.jerseyNumber.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}

final playerFormProvider = NotifierProvider.autoDispose
    .family<PlayerFormNotifier, PlayerFormState, String?>(
      PlayerFormNotifier.new,
    );
