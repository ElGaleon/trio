import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/players/application/player_providers.dart';
import 'package:trio/src/common_widgets/sport_glass_decoration_helper.dart';

class ScoreTrendChart extends ConsumerStatefulWidget {
  const ScoreTrendChart({super.key, required this.match});

  final ScrimmageMatch match;

  @override
  ConsumerState<ScoreTrendChart> createState() => _ScoreTrendChartState();
}

class _ScoreTrendChartState extends ConsumerState<ScoreTrendChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final goalEvents = widget.match.statEvents
        .where((e) => e.type == MatchStatType.goal || e.type == MatchStatType.opponentGoal)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final scoresA = [0.0];
    final scoresB = [0.0];
    for (final e in goalEvents) {
      scoresA.add(e.scoreA.toDouble());
      scoresB.add(e.scoreB.toDouble());
    }

    if (scoresA.length < 2) {
      return const SizedBox.shrink();
    }

    final selectedIndex = _selectedIndex ?? (scoresA.length - 1);
    final players = ref.watch(rankedPlayersProvider);
    final playersById = {for (final p in players) p.id: p};

    return DecoratedBox(
      decoration: sportGlassDecoration(radius: 28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                const Icon(FIcons.activity, size: 18, color: AppColors.violet),
                Expanded(
                  child: Text(
                    'Andamento Punteggio',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                LegendItem(color: AppColors.violet, label: widget.match.teamAName),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: LegendItem(color: AppColors.danger, label: widget.match.teamBName),
                ),
              ],
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final chartWidth = constraints.maxWidth;
                    final totalPoints = scoresA.length - 1;
                    final segmentWidth = totalPoints == 0 ? chartWidth : chartWidth / totalPoints;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final tappedIndex = (details.localPosition.dx / segmentWidth).round();
                        setState(() {
                          _selectedIndex = tappedIndex.clamp(0, totalPoints);
                        });
                      },
                      child: CustomPaint(
                        size: Size(chartWidth, 140),
                        painter: ScoreTrendPainter(
                          scoresA: scoresA,
                          scoresB: scoresB,
                          progress: progress,
                          selectedIndex: selectedIndex,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            if (selectedIndex > 0 && selectedIndex - 1 < goalEvents.length) ...[
              (() {
                final event = goalEvents[selectedIndex - 1];
                final player = event.playerId == null ? null : playersById[event.playerId];
                final elapsed = event.createdAt.difference(widget.match.createdAt);
                final min = elapsed.inMinutes;
                final sec = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
                final scorerName = player?.name ?? (event.type == MatchStatType.goal ? widget.match.teamAName : widget.match.teamBName);
                final isOurGoal = event.type == MatchStatType.goal;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      spacing: 12,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: (isOurGoal ? AppColors.violet : AppColors.danger).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: isOurGoal ? AppColors.violet : AppColors.danger),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isOurGoal ? FIcons.flag : FIcons.circleDot,
                              color: AppColors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 3,
                            children: [
                              Text(
                                isOurGoal ? 'Meta di $scorerName' : 'Meta avversaria',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Punteggio: ${event.scoreA} - ${event.scoreB} · Tempo: $min\'$sec"',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.sportMutedText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })(),
            ] else if (selectedIndex == 0) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    spacing: 12,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            FIcons.play,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 3,
                          children: [
                            Text(
                              'Inizio della partita',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Punteggio di partenza: 0 - 0',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.sportMutedText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        SizedBox(
          width: 8,
          height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class ScoreTrendPainter extends CustomPainter {
  final List<double> scoresA;
  final List<double> scoresB;
  final double progress;
  final int? selectedIndex;

  ScoreTrendPainter({
    required this.scoresA,
    required this.scoresB,
    required this.progress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxScore = math.max(1.0, math.max(scoresA.last, scoresB.last));
    final totalPoints = scoresA.length - 1;

    final gridPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const gridLines = 3;
    for (var i = 0; i <= gridLines; i++) {
      final y = size.height * i / gridLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pointsA = <Offset>[];
    final pointsB = <Offset>[];
    for (var i = 0; i < scoresA.length; i++) {
      final x = totalPoints == 0 ? 0.0 : (size.width) * (i / totalPoints);
      final yA = size.height - (size.height * (scoresA[i] / maxScore));
      final yB = size.height - (size.height * (scoresB[i] / maxScore));
      pointsA.add(Offset(x, yA));
      pointsB.add(Offset(x, yB));
    }

    _drawLine(canvas, pointsA, AppColors.violet, progress);
    _drawLine(canvas, pointsB, AppColors.danger, progress);

    if (totalPoints <= 25) {
      final dotPaint = Paint()..style = PaintingStyle.fill;
      for (var i = 0; i < pointsA.length; i++) {
        if (i * progress >= i) {
          dotPaint.color = AppColors.violet;
          canvas.drawCircle(pointsA[i], 3, dotPaint);
          dotPaint.color = AppColors.danger;
          canvas.drawCircle(pointsB[i], 3, dotPaint);
        }
      }
    }

    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < scoresA.length) {
      final x = totalPoints == 0 ? 0.0 : size.width * (selectedIndex! / totalPoints);
      final linePaint = Paint()
        ..color = AppColors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);

      final dotPaint = Paint()..style = PaintingStyle.fill;

      // Highlight A
      final yA = size.height - (size.height * (scoresA[selectedIndex!] / maxScore));
      dotPaint.color = AppColors.violet.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(x, yA), 8, dotPaint);
      dotPaint.color = AppColors.violet;
      canvas.drawCircle(Offset(x, yA), 5, dotPaint);
      dotPaint.color = AppColors.white;
      canvas.drawCircle(Offset(x, yA), 2.5, dotPaint);

      // Highlight B
      final yB = size.height - (size.height * (scoresB[selectedIndex!] / maxScore));
      dotPaint.color = AppColors.danger.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(x, yB), 8, dotPaint);
      dotPaint.color = AppColors.danger;
      canvas.drawCircle(Offset(x, yB), 5, dotPaint);
      dotPaint.color = AppColors.white;
      canvas.drawCircle(Offset(x, yB), 2.5, dotPaint);
    }
  }

  void _drawLine(Canvas canvas, List<Offset> points, Color color, double animProgress) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final metric = path.computeMetrics().first;
    final animatedPath = metric.extractPath(0, metric.length * animProgress);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(animatedPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant ScoreTrendPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.scoresA != scoresA ||
        oldDelegate.scoresB != scoresB ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
