import 'player_line_preference.dart';
import 'player_role.dart';

class PlayerFormState {
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final GameLine? linePreference;
  final PlayerRole role;
  final bool isExternal;
  final String jerseyNumber;
  final String? profileImagePath;

  PlayerFormState({
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.linePreference,
    required this.role,
    required this.isExternal,
    required this.jerseyNumber,
    this.profileImagePath,
  });

  PlayerFormState copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    GameLine? linePreference,
    PlayerRole? role,
    bool? isExternal,
    String? jerseyNumber,
    String? profileImagePath,
    bool nullifyProfileImagePath = false,
  }) {
    return PlayerFormState(
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
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
