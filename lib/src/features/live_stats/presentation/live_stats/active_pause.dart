import 'package:skrim/src/features/matches/domain/match_stat_type.dart';

class ActivePause {
  const ActivePause({
    required this.type,
    required this.endType,
    required this.title,
    required this.remaining,
    required this.nextOnOffense,
  });

  final MatchStatType type;
  final MatchStatType endType;
  final String title;
  final Duration remaining;
  final bool nextOnOffense;
}
