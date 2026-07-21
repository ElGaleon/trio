import 'match_stat_type.dart';
import 'match_stat_event.dart';

class ScrimmageMatch {
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
  List<String> enabledCustomStatIds;
  String? eventId;
  String? trainingEventId;

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
    List<String>? enabledCustomStatIds,
    this.eventId,
    this.trainingEventId,
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
       teamBRosterIds = teamBRosterIds ?? [],
       enabledCustomStatIds = enabledCustomStatIds ?? [];

  bool get isDraw => scoreA == scoreB;

  bool get teamAWon => scoreA > scoreB;

  int get goals => statEvents.where((e) => e.isGoal).length;

  int get turnovers => statEvents.where((e) => e.isError).length;

  int get completedPasses => statEvents.where((e) => e.isCompletedPass).length;

  int get attemptedPasses => statEvents.where((e) => e.isAttemptedPass).length;

  double ratingDelta(String playerId) {
    return (finalRatings[playerId] ?? initialRatings[playerId] ?? 0) -
        (initialRatings[playerId] ?? finalRatings[playerId] ?? 0);
  }

  bool tracks(MatchStatType type) {
    return enabledStatTypes.contains(type);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toUtc(),
      'teamAIds': teamAIds,
      'teamBIds': teamBIds,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'teamSize': teamSize,
      'offenseVsDefense': offenseVsDefense,
      'teamAName': teamAName,
      'teamBName': teamBName,
      'initialRatings': initialRatings,
      'finalRatings': finalRatings,
      'isExternalOpponent': isExternalOpponent,
      'division': division,
      'tournament': tournament,
      'matchType': matchType,
      'windKmh': windKmh,
      'pointsLimit': pointsLimit,
      'durationMinutes': durationMinutes,
      'location': location,
      'hasHalfTime': hasHalfTime,
      'halfTimeSeconds': halfTimeSeconds,
      'hasTimeouts': hasTimeouts,
      'timeoutsPerTeamPerHalf': timeoutsPerTeamPerHalf,
      'timeoutSeconds': timeoutSeconds,
      'presentPlayerIds': presentPlayerIds,
      'enabledStatTypes': enabledStatTypes.map((type) => type.name).toList(),
      'statEvents': statEvents.map((event) => event.toMap()).toList(),
      'teamARosterIds': teamARosterIds,
      'teamBRosterIds': teamBRosterIds,
      'enabledCustomStatIds': enabledCustomStatIds,
      'eventId': eventId,
      'trainingEventId': trainingEventId,
    };
  }

  static ScrimmageMatch fromMap(Map<dynamic, dynamic> map) {
    return ScrimmageMatch(
      id: map['id'] as String? ?? '',
      createdAt: _dateFrom(map['createdAt']) ?? DateTime.now(),
      teamAIds: List<String>.from(map['teamAIds'] as List? ?? []),
      teamBIds: List<String>.from(map['teamBIds'] as List? ?? []),
      scoreA: (map['scoreA'] as num?)?.toInt() ?? 0,
      scoreB: (map['scoreB'] as num?)?.toInt() ?? 0,
      teamSize: (map['teamSize'] as num?)?.toInt(),
      offenseVsDefense: map['offenseVsDefense'] as bool? ?? false,
      teamAName: map['teamAName'] as String?,
      teamBName: map['teamBName'] as String?,
      initialRatings: _doubleMap(map['initialRatings']),
      finalRatings: _doubleMap(map['finalRatings']),
      isExternalOpponent: map['isExternalOpponent'] as bool? ?? false,
      division: map['division'] as String? ?? 'Mixed',
      tournament: map['tournament'] as String? ?? '',
      matchType: map['matchType'] as String? ?? 'Classic',
      windKmh: (map['windKmh'] as num?)?.toInt() ?? 0,
      pointsLimit: (map['pointsLimit'] as num?)?.toInt() ?? 15,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 80,
      location: map['location'] as String? ?? '',
      hasHalfTime: map['hasHalfTime'] as bool? ?? true,
      halfTimeSeconds: (map['halfTimeSeconds'] as num?)?.toInt() ?? 300,
      hasTimeouts: map['hasTimeouts'] as bool? ?? true,
      timeoutsPerTeamPerHalf:
          (map['timeoutsPerTeamPerHalf'] as num?)?.toInt() ?? 2,
      timeoutSeconds: (map['timeoutSeconds'] as num?)?.toInt() ?? 90,
      presentPlayerIds: List<String>.from(
        map['presentPlayerIds'] as List? ?? [],
      ),
      enabledStatTypes: (map['enabledStatTypes'] as List? ?? [])
          .map(
            (name) => MatchStatType.values.firstWhere(
              (type) => type.name == name,
              orElse: () => MatchStatType.pass,
            ),
          )
          .toList(),
      statEvents: (map['statEvents'] as List? ?? [])
          .whereType<Map>()
          .map(MatchStatEvent.fromMap)
          .toList(),
      teamARosterIds: List<String>.from(map['teamARosterIds'] as List? ?? []),
      teamBRosterIds: List<String>.from(map['teamBRosterIds'] as List? ?? []),
      enabledCustomStatIds: List<String>.from(
        map['enabledCustomStatIds'] as List? ?? [],
      ),
      eventId: map['eventId'] as String?,
      trainingEventId: map['trainingEventId'] as String?,
    );
  }
}

Map<String, double> _doubleMap(Object? value) {
  final raw = value as Map? ?? {};
  return raw.map((key, value) {
    return MapEntry(key.toString(), (value as num).toDouble());
  });
}

DateTime? _dateFrom(Object? value) {
  if (value is DateTime) return value;
  try {
    final dynamic candidate = value;
    final date = candidate?.toDate();
    if (date is DateTime) return date;
  } catch (_) {
    return null;
  }
  return null;
}
