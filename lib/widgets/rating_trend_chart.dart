import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RatingTrendChart extends StatelessWidget {
  const RatingTrendChart({super.key, required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return CustomPaint(
          size: const Size.fromHeight(180),
          painter: _RatingTrendPainter(
            values: values,
            progress: progress,
            colorScheme: Theme.of(context).colorScheme,
          ),
        );
      },
    );
  }
}

class _RatingTrendPainter extends CustomPainter {
  _RatingTrendPainter({
    required this.values,
    required this.progress,
    required this.colorScheme,
  });

  final List<double> values;
  final double progress;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    final borderRadius = BorderRadius.circular(18).toRRect(Offset.zero & size);
    canvas.drawRRect(borderRadius, backgroundPaint);

    final gridPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.09)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), gridPaint);
    }

    if (values.length < 2) {
      _drawSingleValue(canvas, size);
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final spread = math.max(1, maxValue - minValue);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = 18 + (size.width - 36) * (i / (values.length - 1));
      final normalized = (values[i] - minValue) / spread;
      final y = size.height - 24 - (size.height - 48) * normalized;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final metric = path.computeMetrics().first;
    final animatedPath = metric.extractPath(0, metric.length * progress);
    final linePaint = Paint()
      ..color = AppColors.violet
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(animatedPath, linePaint);

    final dotPaint = Paint()..color = AppColors.sportDotSurface;
    final dotBorderPaint = Paint()
      ..color = AppColors.violet
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotBorderPaint);
    }
  }

  void _drawSingleValue(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.violet;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 6, paint);
  }

  @override
  bool shouldRepaint(covariant _RatingTrendPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.values != values ||
        oldDelegate.colorScheme != colorScheme;
  }
}
