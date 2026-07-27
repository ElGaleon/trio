import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/matches/domain/match_stat_event.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/matches/domain/final_stats_summary.dart';
import 'package:skrim/src/features/matches/application/match_detail_provider.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/src/features/matches/domain/match_detail_sub_tab.dart';

class FotMobStatRow extends StatelessWidget {
  final String label;
  final String leftValue;
  final String rightValue;
  final double leftPercent;

  const FotMobStatRow({
    super.key,
    required this.label,
    required this.leftValue,
    required this.rightValue,
    required this.leftPercent,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = leftPercent.isNaN ? 0.5 : leftPercent.clamp(0.0, 1.0);
    final isDual = rightValue != 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        spacing: 6,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leftValue,
                style: TextStyle(
                  color: AppColors.sportForeground(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.sportMutedForeground(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                rightValue,
                style: TextStyle(
                  color: AppColors.sportForeground(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(label),
                tween: Tween(begin: 0.0, end: clamped),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) {
                  final leftFlex = (animValue * 1000).round().clamp(1, 1000);
                  final rightFlex = ((1 - animValue) * 1000).round().clamp(
                    1,
                    1000,
                  );
                  return isDual
                      ? Row(
                          children: [
                            Expanded(
                              flex: leftFlex,
                              child: Container(
                                color: clamped >= 0.5
                                    ? AppColors.violet
                                    : AppColors.violet.withValues(alpha: 0.4),
                              ),
                            ),
                            Container(
                              width: 2,
                              color: AppColors.sportBackgroundMid,
                            ),
                            Expanded(
                              flex: rightFlex,
                              child: Container(
                                color: clamped <= 0.5
                                    ? AppColors.danger
                                    : AppColors.danger.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: leftFlex,
                              child: Container(color: AppColors.violet),
                            ),
                            Expanded(
                              flex: rightFlex,
                              child: Container(
                                color: AppColors.sportForeground(
                                  context,
                                ).withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GroupedMatchStats extends ConsumerWidget {
  const GroupedMatchStats({
    super.key,
    required this.match,
    required this.playersById,
  });

  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(matchDetailSubTabProvider(match.id));
    final summary = FinalStatsSummary.from(match, playersById);
    final events = match.statEvents;
    final opponentGoals = summary.opponentGoals;

    final pointStarts = <int, bool>{};
    for (final event in events) {
      pointStarts.putIfAbsent(event.pointNumber, () => event.oursOnOffense);
    }

    final oLineStarts = pointStarts.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
    final dLineStarts = pointStarts.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toSet();

    final ourGoals = summary.goals;
    final dLineGoals = summary.breaks;

    final opponentOLineStarts = dLineStarts;
    final opponentDLineStarts = oLineStarts;

    final opponentGoalEvents = events.where(
      (e) => e.type == MatchStatType.opponentGoal,
    );
    final opponentOLineGoals = opponentGoalEvents
        .where((event) => opponentOLineStarts.contains(_scoredPoint(event)))
        .length;
    final opponentDLineGoals = summary.breaksConceded;

    final ourTurnovers = summary.turnovers;
    final opponentTurnovers = summary.generatedTurnovers;

    final completedPasses = events
        .where(
          (e) => e.type == MatchStatType.pass || e.type == MatchStatType.huck,
        )
        .length;
    final attemptedPasses =
        completedPasses +
        events
            .where(
              (e) =>
                  e.type == MatchStatType.throwError ||
                  e.type == MatchStatType.catchError,
            )
            .length;
    final passAccuracy = attemptedPasses == 0
        ? 0.0
        : completedPasses / attemptedPasses;

    final playerDefensesTotal = events
        .where(
          (e) =>
              e.type == MatchStatType.defense || e.type == MatchStatType.block,
        )
        .length;

    final totalPoints = ourGoals + opponentGoals;

    final opponentOLineConversion = opponentOLineStarts.isEmpty
        ? 0.0
        : opponentOLineGoals / opponentOLineStarts.length;
    final opponentDLineConversion = opponentDLineStarts.isEmpty
        ? 0.0
        : opponentDLineGoals / opponentDLineStarts.length;

    return GlassDecoration(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 14,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiche Team',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            Row(
              spacing: 8,
              children: [
                _buildSubTabButton(
                  context,
                  ref,
                  'Generali',
                  MatchDetailSubTab.generali,
                ),
                _buildSubTabButton(
                  context,
                  ref,
                  'Attacco',
                  MatchDetailSubTab.attacco,
                ),
                _buildSubTabButton(
                  context,
                  ref,
                  'Difesa',
                  MatchDetailSubTab.difesa,
                ),
              ],
            ),
            if (activeTab == MatchDetailSubTab.generali) ...[
              FotMobStatRow(
                label: 'Mete',
                leftValue: '$ourGoals',
                rightValue: '$opponentGoals',
                leftPercent: totalPoints == 0 ? 0.5 : ourGoals / totalPoints,
              ),
              FotMobStatRow(
                label: 'Palle perse (Turnovers)',
                leftValue: '$ourTurnovers',
                rightValue: '$opponentTurnovers',
                leftPercent: (ourTurnovers + opponentTurnovers) == 0
                    ? 0.5
                    : ourTurnovers / (ourTurnovers + opponentTurnovers),
              ),
              FotMobStatRow(
                label: 'Breaks (Mete in difesa)',
                leftValue: '$dLineGoals',
                rightValue: '$opponentDLineGoals',
                leftPercent: (dLineGoals + opponentDLineGoals) == 0
                    ? 0.5
                    : dLineGoals / (dLineGoals + opponentDLineGoals),
              ),
              FotMobStatRow(
                label: 'Break subiti',
                leftValue: '${summary.breaksConceded}',
                rightValue: 'N/A',
                leftPercent: summary.breaksConceded == 0 ? 0.0 : 1.0,
              ),
              FotMobStatRow(
                label: 'Punti Giocati',
                leftValue: '$totalPoints',
                rightValue: '$totalPoints',
                leftPercent: 0.5,
              ),
            ] else if (activeTab == MatchDetailSubTab.attacco) ...[
              FotMobStatRow(
                label: 'Passaggi Completati',
                leftValue: '$completedPasses',
                rightValue: 'N/A',
                leftPercent: 1.0,
              ),
              FotMobStatRow(
                label: 'Precisione lanci (Pass Accuracy)',
                leftValue: '${(passAccuracy * 100).round()}%',
                rightValue: 'N/A',
                leftPercent: passAccuracy,
              ),
              FotMobStatRow(
                label: 'O-Line Conversion',
                leftValue: '${(summary.oLineEffectiveness * 100).round()}%',
                rightValue: '${(opponentOLineConversion * 100).round()}%',
                leftPercent:
                    (summary.oLineEffectiveness + opponentOLineConversion) == 0
                    ? 0.5
                    : summary.oLineEffectiveness /
                          (summary.oLineEffectiveness +
                              opponentOLineConversion),
              ),
              FotMobStatRow(
                label: 'Attacchi puliti',
                leftValue: '${(summary.cleanOffenseRatio * 100).round()}%',
                rightValue: 'N/A',
                leftPercent: summary.cleanOffenseRatio,
              ),
            ] else if (activeTab == MatchDetailSubTab.difesa) ...[
              FotMobStatRow(
                label: 'Difese / Blocchi (Blocks)',
                leftValue: '$playerDefensesTotal',
                rightValue: 'N/A',
                leftPercent: 1.0,
              ),
              FotMobStatRow(
                label: 'Turnover generati',
                leftValue: '${summary.generatedTurnovers}',
                rightValue: 'N/A',
                leftPercent: summary.dLineTurnoverRatio,
              ),
              FotMobStatRow(
                label: 'Conversione dopo turnover',
                leftValue: '${(summary.dLineConversionRatio * 100).round()}%',
                rightValue: '${(opponentDLineConversion * 100).round()}%',
                leftPercent:
                    (summary.dLineConversionRatio + opponentDLineConversion) ==
                        0
                    ? 0.5
                    : summary.dLineConversionRatio /
                          (summary.dLineConversionRatio +
                              opponentDLineConversion),
              ),
              FotMobStatRow(
                label: 'Turnover generati / punti in difesa',
                leftValue: '${(summary.dLineTurnoverRatio * 100).round()}%',
                rightValue: 'N/A',
                leftPercent: summary.dLineTurnoverRatio,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    MatchDetailSubTab tab,
  ) {
    final currentTab = ref.watch(matchDetailSubTabProvider(match.id));
    final selected = currentTab == tab;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            ref.read(matchDetailSubTabProvider(match.id).notifier).setTab(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.violet.withValues(alpha: 0.24)
                : AppColors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.violet
                  : AppColors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.sportForeground(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  int _scoredPoint(MatchStatEvent event) {
    return event.pointNumber > 1 ? event.pointNumber - 1 : event.pointNumber;
  }
}
