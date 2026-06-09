import 'player.dart';

class PlayerFormState {
  final String name;
  final PlayerLinePreference? linePreference;
  final PlayerRole role;
  final bool isExternal;
  final String jerseyNumber;
  final String? profileImagePath;

  PlayerFormState({
    required this.name,
    this.linePreference,
    required this.role,
    required this.isExternal,
    required this.jerseyNumber,
    this.profileImagePath,
  });

  PlayerFormState copyWith({
    String? name,
    PlayerLinePreference? linePreference,
    PlayerRole? role,
    bool? isExternal,
    String? jerseyNumber,
    String? profileImagePath,
    bool nullifyProfileImagePath = false,
  }) {
    return PlayerFormState(
      name: name ?? this.name,
      linePreference: linePreference ?? this.linePreference,
      role: role ?? this.role,
      isExternal: isExternal ?? this.isExternal,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      profileImagePath: nullifyProfileImagePath
          ? null
          : (profileImagePath ?? this.profileImagePath),
    );
  }
}
