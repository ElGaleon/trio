import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';
import 'stat_button.dart';

class LegendRow extends StatelessWidget {
  const LegendRow({super.key, required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        spacing: 10,
        children: [
          SizedBox(
            width: 44,
            child: StatButton(label: code, onTap: () {}),
          ),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
