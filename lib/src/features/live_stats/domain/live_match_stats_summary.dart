import 'package:trio/src/features/matches/domain/match_derived_stats.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'live_named_count.dart';

class LiveMatchStatsSummary {
  const LiveMatchStatsSummary({
    required this.goals,
    required this.opponentGoals,
    required this.turnovers,
    required this.breaks,
    required this.breaksConceded,
    required this.generatedTurnovers,
    required this.passAccuracy,
    required this.oLineEffectiveness,
    required this.cleanOffenseRatio,
    required this.dLineTurnoverRatio,
    required this.dLineConversionRatio,
    required this.topScorer,
    required this.mostAssist,
    required this.mostSecondaryAssist,
    required this.mostTouches,
    required this.bestDefender,
    required this.mostPlayed,
    required this.bestConnection,
    required this.bestAssistGoalPair,
    required this.pointsPlayed,
  });

  final int goals;
  final int opponentGoals;
  final int turnovers;
  final int breaks;
  final int breaksConceded;
  final int generatedTurnovers;
  final double passAccuracy;
  final double oLineEffectiveness;
  final double cleanOffenseRatio;
  final double dLineTurnoverRatio;
  final double dLineConversionRatio;
  final String topScorer;
  final String mostAssist;
  final String mostSecondaryAssist;
  final String mostTouches;
  final String bestDefender;
  final String mostPlayed;
  final String bestConnection;
  final String bestAssistGoalPair;
  final List<LiveNamedCount> pointsPlayed;

  static LiveMatchStatsSummary from(
    ScrimmageMatch match,
    Map<String, Player> playersById,
  ) {
    final stats = MatchDerivedStats.from(match, playersById);

    return LiveMatchStatsSummary(
      goals: stats.goals,
      opponentGoals: stats.opponentGoals,
      turnovers: stats.turnovers,
      breaks: stats.breaks,
      breaksConceded: stats.breaksConceded,
      generatedTurnovers: stats.generatedTurnovers,
      passAccuracy: stats.passAccuracy,
      oLineEffectiveness: stats.oLineEffectiveness,
      cleanOffenseRatio: stats.cleanOffenseRatio,
      dLineTurnoverRatio: stats.dLineTurnoverRatio,
      dLineConversionRatio: stats.dLineConversionRatio,
      topScorer: stats.topScorer,
      mostAssist: stats.mostAssist,
      mostSecondaryAssist: stats.mostSecondaryAssist,
      mostTouches: stats.mostTouches,
      bestDefender: stats.bestDefender,
      mostPlayed: stats.mostPlayed,
      bestConnection: stats.bestConnection,
      bestAssistGoalPair: stats.bestAssistGoalPair,
      pointsPlayed: stats.pointsPlayed
          .map((item) => LiveNamedCount(item.name, item.value))
          .toList(),
    );
  }
}
