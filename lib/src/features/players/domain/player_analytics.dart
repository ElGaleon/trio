import 'player.dart';
import 'player_stats_card_data.dart';
import 'group_stats.dart';

class PlayerAnalytics {
  const PlayerAnalytics({
    required this.players,
    required this.cards,
    required this.group,
  });

  final List<Player> players;
  final List<PlayerStatsCardData> cards;
  final GroupStats group;

  PlayerStatsCardData? byId(String? playerId) {
    if (playerId == null) return _firstOrNull(cards);
    return _firstOrNull(cards.where((card) => card.player.id == playerId)) ??
        _firstOrNull(cards);
  }
}

T? _firstOrNull<T>(Iterable<T> values) {
  final iterator = values.iterator;
  return iterator.moveNext() ? iterator.current : null;
}
