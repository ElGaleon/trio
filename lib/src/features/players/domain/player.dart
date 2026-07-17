import 'package:trio/src/constants/app_constants.dart';
import 'player_line_preference.dart';
import 'player_role.dart';

class Player {
  Player({
    required this.id,
    required this.name,
    this.rating = AppConstants.initialRating,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.linePreference,
    this.role = PlayerRole.cutter,
    this.profileImagePath,
    this.isExternal = false,
    this.jerseyNumber,
  });

  final String id;
  String name;
  double rating;
  int matchesPlayed;
  int wins;
  int losses;
  PlayerLinePreference? linePreference;
  PlayerRole role;
  String? profileImagePath;
  bool isExternal;
  int? jerseyNumber;

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    List<String> split = trimmed.split(" ");
    if (split.length == 1) {
      return trimmed[0].toUpperCase();
    }
    return (split.first[0] + split[1][0]).toUpperCase();
  }

  double get winRate => matchesPlayed == 0 ? 0 : wins / matchesPlayed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'linePreference': linePreference.name,
      'role': role.name,
      'profileImagePath': profileImagePath,
      'isExternal': isExternal,
    };
  }

  static Player fromMap(Map<dynamic, dynamic> map) {
    return Player(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      linePreference: PlayerLinePreference.values.firstWhere(
        (e) => e.name == map['linePreference'],
        orElse: () => PlayerLinePreference.offense,
      ),
      role: PlayerRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => PlayerRole.cutter,
      ),
      profileImagePath: map['profileImagePath'] as String?,
      isExternal: map['isExternal'] as bool? ?? false,
    );
  }
}
