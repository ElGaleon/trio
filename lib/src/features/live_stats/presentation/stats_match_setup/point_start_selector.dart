import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/shared/sport_filter_pill.dart';

class PointStartSelector extends StatelessWidget {
  const PointStartSelector({
    super.key,
    required this.startOnOffense,
    required this.onChanged,
  });

  final bool startOnOffense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: SportFilterPill(
            label: 'Partiamo in attacco',
            selected: startOnOffense,
            icon: FIcons.arrowUpRight,
            onPressed: () => onChanged(true),
          ),
        ),
        Expanded(
          child: SportFilterPill(
            label: 'Partiamo in difesa',
            selected: !startOnOffense,
            icon: FIcons.shield,
            onPressed: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}
