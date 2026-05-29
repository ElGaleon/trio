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
  }) : teamSize = teamSize ?? teamAIds.length,
       teamAName = teamAName ?? (offenseVsDefense ? 'Attacco' : 'A'),
       teamBName = teamBName ?? (offenseVsDefense ? 'Difesa' : 'B'),
       initialRatings = initialRatings ?? {},
       finalRatings = finalRatings ?? {};

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

  bool get isDraw => scoreA == scoreB;

  bool get teamAWon => scoreA > scoreB;

  double ratingDelta(String playerId) {
    return (finalRatings[playerId] ?? initialRatings[playerId] ?? 0) -
        (initialRatings[playerId] ?? finalRatings[playerId] ?? 0);
  }
}
