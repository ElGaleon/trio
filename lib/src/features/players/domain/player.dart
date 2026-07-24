import 'package:trio/src/constants/app_constants.dart';
import 'player_line_preference.dart';
import 'player_role.dart';

class Player {
  Player({
    required this.id,
    required this.name,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.rating = AppConstants.initialRating,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.linePreference,
    this.role = PlayerRole.cutter,
    this.profileImagePath,
    this.accountUserId,
    this.isExternal = false,
    this.jerseyNumber,
  });

  final String id;
  String name;
  String firstName;
  String lastName;
  String email;
  double rating;
  int matchesPlayed;
  int wins;
  int losses;
  PlayerLinePreference? linePreference;
  PlayerRole role;
  String? profileImagePath;
  String? accountUserId;
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

  String get fullName => [
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'rating': rating,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'linePreference': linePreference?.name,
      'role': role.name,
      'profileImagePath': profileImagePath,
      'accountUserId': accountUserId,
      'isExternal': isExternal,
      'jerseyNumber': jerseyNumber,
    };
  }

  static Player fromMap(Map<dynamic, dynamic> map) {
    final oldName = map['name'] as String? ?? '';
    return Player(
      id: map['id'] as String? ?? '',
      name: oldName,
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? AppConstants.initialRating,
      matchesPlayed: (map['matchesPlayed'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      linePreference: map['linePreference'] == null
          ? null
          : PlayerLinePreference.values.firstWhere(
              (e) => e.name == map['linePreference'],
              orElse: () => PlayerLinePreference.offense,
            ),
      role: PlayerRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => PlayerRole.cutter,
      ),
      profileImagePath: map['profileImagePath'] as String?,
      accountUserId: map['accountUserId'] as String?,
      isExternal: map['isExternal'] as bool? ?? false,
      jerseyNumber: (map['jerseyNumber'] as num?)?.toInt(),
    );
  }
}
