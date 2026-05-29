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
  });

  final String id;
  String name;
  double rating;
  int matchesPlayed;
  int wins;
  int losses;
  PlayerLinePreference linePreference;
  PlayerRole role;

  String get initials {
    List<String> split = name.split(" ");
    if (split.length == 1) {
      return name[0];
    }
    return split.first[0] + split[1][0];
  }

  double get winRate => matchesPlayed == 0 ? 0 : wins / matchesPlayed;
}
