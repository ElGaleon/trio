import '../app_constants.dart';

enum PlayerLinePreference {
  offense('Attacco'),
  defense('Difesa');

  const PlayerLinePreference(this.label);

  final String label;
}

enum PlayerRole {
  handler('Handler'),
  cutter('Cutter');

  const PlayerRole(this.label);

  final String label;
}

class Player {
  Player({
    required this.id,
    required this.name,
    this.rating = AppConstants.initialRating,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.linePreference = PlayerLinePreference.offense,
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
  PlayerLinePreference linePreference;
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
}
