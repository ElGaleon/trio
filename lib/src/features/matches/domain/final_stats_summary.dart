import 'package:trio/src/features/players/domain/player.dart';
import 'match_derived_stats.dart';
import 'scrimmage_match.dart';
import 'named_count.dart';

class FinalStatsSummary {
  const FinalStatsSummary({
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
  final List<NamedCount> pointsPlayed;

  static FinalStatsSummary from(
    ScrimmageMatch match,
    Map<String, Player> playersById,
  ) {
    final stats = MatchDerivedStats.from(match, playersById);

    return FinalStatsSummary(
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
          .map((item) => NamedCount(item.name, item.value))
          .toList(),
    );
  }

  // Helper field needed by some widgets if they references it:
  String percent(double value) => '${(value * 100).round()}%';
}
