import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class StatsSetupStepHeader extends StatelessWidget {
  const StatsSetupStepHeader({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Info', 'Presenti', 'Stats', 'Linea'];
    return Row(
      spacing: 8,
      children: List.generate(labels.length, (index) {
        final active = index == step;
        final completed = index < step;
        return Expanded(
          child: FBadge(
            variant: active || completed ? .primary : .outline,
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
