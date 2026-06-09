class ScrimmageMatch {
  ScrimmageMatch({
    required this.id,
    required this.createdAt,
    required this.teamAIds,
    required this.teamBIds,
    required this.scoreA,
    required this.scoreB,
    int? teamSize,
    this.offenseVsDefense = false,
    String? teamAName,
    String? teamBName,
    Map<String, double>? initialRatings,
    Map<String, double>? finalRatings,
    this.isExternalOpponent = false,
    this.division = 'Mixed',
    this.tournament = '',
    this.matchType = 'Classic',
    this.windKmh = 0,
    this.pointsLimit = 15,
    this.durationMinutes = 80,
    this.location = '',
    this.hasHalfTime = true,
    this.halfTimeSeconds = 300,
    this.hasTimeouts = true,
    this.timeoutsPerTeamPerHalf = 2,
    this.timeoutSeconds = 90,
    List<String>? presentPlayerIds,
    List<MatchStatType>? enabledStatTypes,
    List<MatchStatEvent>? statEvents,
    List<String>? teamARosterIds,
    List<String>? teamBRosterIds,
  }) : teamSize = teamSize ?? teamAIds.length,
       teamAName = teamAName ?? (offenseVsDefense ? 'Attacco' : 'A'),
       teamBName = teamBName ?? (offenseVsDefense ? 'Difesa' : 'B'),
       initialRatings = initialRatings ?? {},
       finalRatings = finalRatings ?? {},
       presentPlayerIds =
           presentPlayerIds ?? {...teamAIds, ...teamBIds}.toList(),
       enabledStatTypes = enabledStatTypes ?? MatchStatType.defaultEnabled,
       statEvents = statEvents ?? [],
       teamARosterIds = teamARosterIds ?? [],
       teamBRosterIds = teamBRosterIds ?? [];

  final String id;
  final DateTime createdAt;
  List<String> teamAIds;
  List<String> teamBIds;
  int scoreA;
  int scoreB;
  int teamSize;
  bool offenseVsDefense;
  String teamAName;
  String teamBName;
  Map<String, double> initialRatings;
  Map<String, double> finalRatings;
  bool isExternalOpponent;
  String division;
  String tournament;
  String matchType;
  int windKmh;
  int pointsLimit;
  int durationMinutes;
  String location;
  bool hasHalfTime;
  int halfTimeSeconds;
  bool hasTimeouts;
  int timeoutsPerTeamPerHalf;
  int timeoutSeconds;
  List<String> presentPlayerIds;
  List<MatchStatType> enabledStatTypes;
  List<MatchStatEvent> statEvents;
  List<String> teamARosterIds;
  List<String> teamBRosterIds;

  bool get isDraw => scoreA == scoreB;

  bool get teamAWon => scoreA > scoreB;

  double ratingDelta(String playerId) {
    return (finalRatings[playerId] ?? initialRatings[playerId] ?? 0) -
        (initialRatings[playerId] ?? finalRatings[playerId] ?? 0);
  }

  bool tracks(MatchStatType type) {
    return enabledStatTypes.contains(type);
  }
}

enum MatchStatType {
  pass,
  huck,
  assist,
  goal,
  defense,
  catchDisc,
  stallOut,
  block,
  openError,
  deepError,
  resetError,
  throwError,
  catchError,
  opponentGoal,
  opponentError,
  timeout,
  injury,
  halfTime,
  timeoutEnd,
  halfTimeEnd,
  matchEnd,
  lineup,
  pull;

  String get label {
    return switch (this) {
      MatchStatType.pass => 'Passaggio',
      MatchStatType.huck => 'Huck',
      MatchStatType.assist => 'Assist',
      MatchStatType.goal => 'Meta',
      MatchStatType.defense => 'Difesa',
      MatchStatType.catchDisc => 'Catch',
      MatchStatType.stallOut => 'Stall out',
      MatchStatType.block => 'Block',
      MatchStatType.openError => 'Aperto',
      MatchStatType.deepError => 'Buco',
      MatchStatType.resetError => 'Reset',
      MatchStatType.throwError => 'Errore lancio',
      MatchStatType.catchError => 'Errore presa',
      MatchStatType.opponentGoal => 'Meta avversaria',
      MatchStatType.opponentError => 'Errore avversario',
      MatchStatType.timeout => 'Timeout',
      MatchStatType.injury => 'Infortunio',
      MatchStatType.halfTime => 'Half time',
      MatchStatType.timeoutEnd => 'Fine timeout',
      MatchStatType.halfTimeEnd => 'Fine half time',
      MatchStatType.matchEnd => 'Fine partita',
      MatchStatType.lineup => 'Linea',
      MatchStatType.pull => 'Pull',
    };
  }

  static List<MatchStatType> get defaultEnabled {
    return const [
      MatchStatType.pass,
      MatchStatType.huck,
      MatchStatType.catchDisc,
      MatchStatType.stallOut,
      MatchStatType.block,
      MatchStatType.pull,
      MatchStatType.openError,
      MatchStatType.deepError,
      MatchStatType.resetError,
      MatchStatType.throwError,
      MatchStatType.catchError,
      MatchStatType.opponentError,
    ];
  }

  bool get isError {
    return this == MatchStatType.throwError ||
        this == MatchStatType.catchError ||
        this == MatchStatType.stallOut ||
        this == MatchStatType.openError ||
        this == MatchStatType.deepError ||
        this == MatchStatType.resetError;
  }
}

class MatchStatEvent {
  const MatchStatEvent({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.pointNumber,
    required this.scoreA,
    required this.scoreB,
    required this.oursOnOffense,
    this.playerId,
    this.discHolderId,
    this.lineupIds = const [],
    this.description,
    this.pullDurationSeconds,
    this.pullInBounds,
    this.statValue,
  });

  final String id;
  final MatchStatType type;
  final DateTime createdAt;
  final int pointNumber;
  final int scoreA;
  final int scoreB;
  final bool oursOnOffense;
  final String? playerId;
  final String? discHolderId;
  final List<String> lineupIds;
  final String? description;
  final int? pullDurationSeconds;
  final bool? pullInBounds;
  final double? statValue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'createdAt': createdAt,
      'pointNumber': pointNumber,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'oursOnOffense': oursOnOffense,
      'playerId': playerId,
      'discHolderId': discHolderId,
      'lineupIds': lineupIds,
      'description': description,
      'pullDurationSeconds': pullDurationSeconds,
      'pullInBounds': pullInBounds,
      'statValue': statValue,
    };
  }

  static MatchStatEvent fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type'] as String? ?? MatchStatType.pass.name;
    return MatchStatEvent(
      id:
          map['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: MatchStatType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => MatchStatType.pass,
      ),
      createdAt: map['createdAt'] as DateTime? ?? DateTime.now(),
      pointNumber: map['pointNumber'] as int? ?? 1,
      scoreA: map['scoreA'] as int? ?? 0,
      scoreB: map['scoreB'] as int? ?? 0,
      oursOnOffense: map['oursOnOffense'] as bool? ?? true,
      playerId: map['playerId'] as String?,
      discHolderId: map['discHolderId'] as String?,
      lineupIds: List<String>.from(map['lineupIds'] as List? ?? []),
      description: map['description'] as String?,
      pullDurationSeconds: map['pullDurationSeconds'] as int?,
      pullInBounds: map['pullInBounds'] as bool?,
      statValue: (map['statValue'] as num?)?.toDouble(),
    );
  }
}
