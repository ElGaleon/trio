import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'player_stats_card_data.dart';

class PlayerDetailStats {
  const PlayerDetailStats({
    required this.matches,
    required this.tournaments,
    required this.data,
  });

  final List<ScrimmageMatch> matches;
  final List<String> tournaments;
  final PlayerStatsCardData data;
}
