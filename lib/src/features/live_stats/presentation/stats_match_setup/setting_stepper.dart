import 'package:flutter/material.dart';

import 'package:skrim/theme/app_colors.dart';
import 'mini_icon_button.dart';

class SettingStepper extends StatelessWidget {
  const SettingStepper({
    super.key,
    required this.label,
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String suffix;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.sportMutedForeground(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          MiniIconButton(
            icon: Icons.remove,
            onTap: () => onChanged((value - step).clamp(min, max)),
          ),
          SizedBox(
            width: 78,
            child: Text(
              suffix.isEmpty ? '$value' : '$value $suffix',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          MiniIconButton(
            icon: Icons.add,
            onTap: () => onChanged((value + step).clamp(min, max)),
          ),
        ],
      ),
    );
  }
}
