import 'package:flutter/material.dart';

import 'package:trio/src/shared/sport_screen_shell.dart';

class WeekdayLabel extends StatelessWidget {
  const WeekdayLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: sportMutedText,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
