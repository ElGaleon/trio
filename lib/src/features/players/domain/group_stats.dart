import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'player_stats_card_data.dart';

class GroupStats {
  const GroupStats({
    required this.playerCount,
    required this.matches,
    required this.averageRating,
    required this.averageWinRate,
    required this.goals,
    required this.assists,
    required this.defenses,
    required this.errors,
    required this.pulls,
    required this.pullInRate,
  });

  final int playerCount;
  final int matches;
  final double averageRating;
  final double averageWinRate;
  final int goals;
  final int assists;
  final int defenses;
  final int errors;
  final int pulls;
  final double pullInRate;

  static GroupStats from(
    List<PlayerStatsCardData> cards,
    List<ScrimmageMatch> matches,
    Set<String> playerIds,
  ) {
    final filteredEvents = matches.expand((match) {
      return match.statEvents.where((event) {
        final id = event.playerId;
        return id != null && playerIds.contains(id);
      });
    }).toList();
    final pulls = filteredEvents.where((e) => e.type == MatchStatType.pull);
    final pullCount = pulls.length;
    final inBounds = pulls.where((e) => e.pullInBounds == true).length;

    return GroupStats(
      playerCount: cards.length,
      matches: cards.fold(0, (total, card) => total + card.matchesPlayed),
      averageRating: cards.isEmpty
          ? 0
          : cards.fold<double>(0, (total, card) => total + card.player.rating) /
                cards.length,
      averageWinRate: cards.isEmpty
          ? 0
          : cards.fold<double>(0, (total, card) => total + card.winRate) /
                cards.length,
      goals: filteredEvents.where((e) => e.type == MatchStatType.goal).length,
      assists: filteredEvents
          .where((e) => e.type == MatchStatType.assist)
          .length,
      defenses: filteredEvents
          .where(
            (e) =>
                e.type == MatchStatType.defense ||
                e.type == MatchStatType.block,
          )
          .length,
      errors: filteredEvents.where((e) => e.type.isError).length,
      pulls: pullCount,
      pullInRate: pullCount == 0 ? 0 : inBounds / pullCount,
    );
  }
}
