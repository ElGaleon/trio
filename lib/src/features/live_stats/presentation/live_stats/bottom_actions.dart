import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/shared/sport_glass_decoration_helper.dart';
import 'package:trio/theme/app_colors.dart';
import 'general_action_button.dart';
import 'square_action_button.dart';

class BottomActions extends StatelessWidget {
  const BottomActions({
    super.key,
    required this.oursOnOffense,
    required this.showThrowaway,
    required this.timeoutLabel,
    this.goalLabel = 'GOAL',
    this.opponentGoalLabel = 'META AVV',
    this.opponentErrorLabel = 'THROWAWAY',
    required this.onGoal,
    required this.onOpponentGoal,
    required this.onOpponentError,
    required this.onPull,
    required this.onTimeout,
    required this.onInjury,
    required this.onUndo,
  });

  final bool oursOnOffense;
  final bool showThrowaway;
  final String timeoutLabel;
  final String goalLabel;
  final String opponentGoalLabel;
  final String opponentErrorLabel;
  final VoidCallback onGoal;
  final VoidCallback onOpponentGoal;
  final VoidCallback onOpponentError;
  final VoidCallback? onPull;
  final VoidCallback? onTimeout;
  final VoidCallback onInjury;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return GlassDecoration(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                if (oursOnOffense || showThrowaway)
                  Expanded(
                    flex: oursOnOffense ? 5 : 4,
                    child: GeneralActionButton(
                      label: oursOnOffense ? goalLabel : opponentErrorLabel,
                      icon: oursOnOffense ? FIcons.flag : FIcons.rotateCcw,
                      accent: AppColors.violet,
                      onTap: oursOnOffense ? onGoal : onOpponentError,
                    ),
                  ),
                if (!oursOnOffense)
                  Expanded(
                    flex: 3,
                    child: GeneralActionButton(
                      label: opponentGoalLabel,
                      icon: FIcons.circleDot,
                      accent: AppColors.danger,
                      compact: true,
                      onTap: onOpponentGoal,
                    ),
                  ),
                SquareActionButton(
                  icon: FIcons.undo2,
                  label: 'Undo',
                  onTap: onUndo,
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                if (onPull != null)
                  Expanded(
                    child: GeneralActionButton(
                      label: 'PULL',
                      icon: FIcons.send,
                      accent: AppColors.violet,
                      compact: true,
                      onTap: onPull!,
                    ),
                  ),
                Expanded(
                  child: GeneralActionButton(
                    label: timeoutLabel,
                    icon: FIcons.timer,
                    accent: AppColors.violetLight,
                    compact: true,
                    onTap: onTimeout ?? () {},
                  ),
                ),
                SquareActionButton(
                  icon: FIcons.plus,
                  label: 'Infortunio',
                  onTap: onInjury,
                  danger: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
