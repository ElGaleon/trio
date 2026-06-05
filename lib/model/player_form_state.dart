import 'player.dart';

class PlayerFormState {
  final String name;
  final PlayerLinePreference linePreference;
  final PlayerRole role;
  final bool isExternal;
  final String? profileImagePath;

  PlayerFormState({
    required this.name,
    required this.linePreference,
    required this.role,
    required this.isExternal,
    this.profileImagePath,
  });

  PlayerFormState copyWith({
    String? name,
    PlayerLinePreference? linePreference,
    PlayerRole? role,
    bool? isExternal,
    String? profileImagePath,
    bool nullifyProfileImagePath = false,
  }) {
    return PlayerFormState(
      name: name ?? this.name,
      linePreference: linePreference ?? this.linePreference,
      role: role ?? this.role,
      isExternal: isExternal ?? this.isExternal,
      profileImagePath: nullifyProfileImagePath ? null : (profileImagePath ?? this.profileImagePath),
    );
  }
}
