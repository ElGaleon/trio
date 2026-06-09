import 'scrimmage_match.dart';

class StatsMatchSetupState {
  final int step;
  final String teamName;
  final String opponentName;
  final String tournament;
  final String location;
  final String division;
  final String matchType;
  final int teamSize;
  final int windKmh;
  final int pointsLimit;
  final int durationMinutes;
  final bool hasHalfTime;
  final int halfTimeSeconds;
  final bool hasTimeouts;
  final int timeoutsPerTeamPerHalf;
  final int timeoutSeconds;
  final Set<MatchStatType> enabledStatTypes;
  final Set<String> presentPlayerIds;
  final bool startOnOffense;
  final Set<String> selectedPlayerIds;
  final bool isInternalScrimmage;
  final Set<String> teamARosterIds;
  final Set<String> teamBRosterIds;
  final bool isTrainingMatch;
  final bool isAttackVsDefense;

  StatsMatchSetupState({
    required this.step,
    required this.teamName,
    required this.opponentName,
    required this.tournament,
    required this.location,
    required this.division,
    required this.matchType,
    required this.teamSize,
    required this.windKmh,
    required this.pointsLimit,
    required this.durationMinutes,
    required this.hasHalfTime,
    required this.halfTimeSeconds,
    required this.hasTimeouts,
    required this.timeoutsPerTeamPerHalf,
    required this.timeoutSeconds,
    required this.enabledStatTypes,
    required this.presentPlayerIds,
    required this.startOnOffense,
    required this.selectedPlayerIds,
    required this.isInternalScrimmage,
    required this.teamARosterIds,
    required this.teamBRosterIds,
    required this.isTrainingMatch,
    required this.isAttackVsDefense,
  });

  StatsMatchSetupState copyWith({
    int? step,
    String? teamName,
    String? opponentName,
    String? tournament,
    String? location,
    String? division,
    String? matchType,
    int? teamSize,
    int? windKmh,
    int? pointsLimit,
    int? durationMinutes,
    bool? hasHalfTime,
    int? halfTimeSeconds,
    bool? hasTimeouts,
    int? timeoutsPerTeamPerHalf,
    int? timeoutSeconds,
    Set<MatchStatType>? enabledStatTypes,
    Set<String>? presentPlayerIds,
    bool? startOnOffense,
    Set<String>? selectedPlayerIds,
    bool? isInternalScrimmage,
    Set<String>? teamARosterIds,
    Set<String>? teamBRosterIds,
    bool? isTrainingMatch,
    bool? isAttackVsDefense,
  }) {
    return StatsMatchSetupState(
      step: step ?? this.step,
      teamName: teamName ?? this.teamName,
      opponentName: opponentName ?? this.opponentName,
      tournament: tournament ?? this.tournament,
      location: location ?? this.location,
      division: division ?? this.division,
      matchType: matchType ?? this.matchType,
      teamSize: teamSize ?? this.teamSize,
      windKmh: windKmh ?? this.windKmh,
      pointsLimit: pointsLimit ?? this.pointsLimit,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      hasHalfTime: hasHalfTime ?? this.hasHalfTime,
      halfTimeSeconds: halfTimeSeconds ?? this.halfTimeSeconds,
      hasTimeouts: hasTimeouts ?? this.hasTimeouts,
      timeoutsPerTeamPerHalf:
          timeoutsPerTeamPerHalf ?? this.timeoutsPerTeamPerHalf,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      enabledStatTypes: enabledStatTypes ?? this.enabledStatTypes,
      presentPlayerIds: presentPlayerIds ?? this.presentPlayerIds,
      startOnOffense: startOnOffense ?? this.startOnOffense,
      selectedPlayerIds: selectedPlayerIds ?? this.selectedPlayerIds,
      isInternalScrimmage: isInternalScrimmage ?? this.isInternalScrimmage,
      teamARosterIds: teamARosterIds ?? this.teamARosterIds,
      teamBRosterIds: teamBRosterIds ?? this.teamBRosterIds,
      isTrainingMatch: isTrainingMatch ?? this.isTrainingMatch,
      isAttackVsDefense: isAttackVsDefense ?? this.isAttackVsDefense,
    );
  }
}
