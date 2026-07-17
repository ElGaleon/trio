class RecentMatchTeam {
  const RecentMatchTeam({
    required this.name,
    required this.playerIds,
    required this.playerNames,
    required this.lastUsedAt,
  });

  final String name;
  final List<String> playerIds;
  final List<String> playerNames;
  final DateTime lastUsedAt;
}
