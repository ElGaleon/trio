class MatchFormState {
  final int step;
  final int teamSize;
  final bool offenseVsDefense;
  final String teamAName;
  final String teamBName;
  final Set<String> teamAIds;
  final Set<String> teamBIds;
  final int scoreA;
  final int scoreB;

  MatchFormState({
    required this.step,
    required this.teamSize,
    required this.offenseVsDefense,
    required this.teamAName,
    required this.teamBName,
    required this.teamAIds,
    required this.teamBIds,
    required this.scoreA,
    required this.scoreB,
  });

  MatchFormState copyWith({
    int? step,
    int? teamSize,
    bool? offenseVsDefense,
    String? teamAName,
    String? teamBName,
    Set<String>? teamAIds,
    Set<String>? teamBIds,
    int? scoreA,
    int? scoreB,
  }) {
    return MatchFormState(
      step: step ?? this.step,
      teamSize: teamSize ?? this.teamSize,
      offenseVsDefense: offenseVsDefense ?? this.offenseVsDefense,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      teamAIds: teamAIds ?? this.teamAIds,
      teamBIds: teamBIds ?? this.teamBIds,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
    );
  }
}
