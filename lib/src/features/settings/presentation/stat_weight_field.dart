import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'package:skrim/theme/app_colors.dart';

class StatWeightField extends StatelessWidget {
  const StatWeightField({
    super.key,
    required this.type,
    required this.controller,
  });

  final MatchStatType type;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Text(
            type.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.sportForeground(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          width: 96,
          child: FTextFormField(
            control: FTextFieldControl.managed(controller: controller),
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            hint: '0',
          ),
        ),
      ],
    );
  }
}
