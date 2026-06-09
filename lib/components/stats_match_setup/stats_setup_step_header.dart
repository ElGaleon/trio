import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class StatsSetupStepHeader extends StatelessWidget {
  const StatsSetupStepHeader({
    super.key,
    required this.step,
    required this.labels,
  });

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: List.generate(labels.length, (index) {
        final active = index == step;
        final completed = index < step;
        return Expanded(
          child: FBadge(
            variant: active || completed ? FBadgeVariant.primary : FBadgeVariant.outline,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                Icon(completed ? FIcons.check : FIcons.circle, size: 12),
                Flexible(child: Text(labels[index])),
              ],
            ),
          ),
        );
      }),
    );
  }
}
