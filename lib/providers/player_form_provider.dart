import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../model/player.dart';
import '../model/player_form_state.dart';
import 'elo_providers.dart';

class PlayerFormNotifier extends Notifier<PlayerFormState> {
  final String? arg;
  PlayerFormNotifier(this.arg);

  @override
  PlayerFormState build() {
    if (arg == null) {
      return PlayerFormState(
        name: '',
        linePreference: PlayerLinePreference.offense,
        role: PlayerRole.cutter,
        isExternal: false,
        jerseyNumber: '',
        profileImagePath: null,
      );
    }

    final repository = ref.read(eloRepositoryProvider);
    final player = repository.playersBox.get(arg);
    if (player == null) {
      return PlayerFormState(
        name: '',
        linePreference: PlayerLinePreference.offense,
        role: PlayerRole.cutter,
        isExternal: false,
        jerseyNumber: '',
        profileImagePath: null,
      );
    }

    return PlayerFormState(
      name: player.name,
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

  void updateJerseyNumber(String value) {
    state = state.copyWith(jerseyNumber: value);
  }

  void updateLinePreference(PlayerLinePreference line) {
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

  Future<void> save(String? playerId) async {
    final repository = ref.read(eloRepositoryProvider);
    if (playerId == null) {
      await repository.addPlayerWithLine(
        state.name,
        state.linePreference,
        state.role,
        state.profileImagePath,
        state.isExternal,
        _jerseyNumberOrNull(),
      );
    } else {
      final player = repository.playersBox.get(playerId);
      if (player != null) {
        await repository.savePlayer(
          player,
          name: state.name,
          linePreference: state.linePreference,
          role: state.role,
          profileImagePath: state.profileImagePath,
          isExternal: state.isExternal,
          jerseyNumber: _jerseyNumberOrNull(),
        );
      }
    }
  }

  int? _jerseyNumberOrNull() {
    final trimmed = state.jerseyNumber.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}

final playerFormProvider =
    NotifierProvider.family<PlayerFormNotifier, PlayerFormState, String?>(
      PlayerFormNotifier.new,
    );
