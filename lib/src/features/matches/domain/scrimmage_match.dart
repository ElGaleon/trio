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
}
