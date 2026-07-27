import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/matches/application/matches_view_mode.dart';
import 'header_switch_icon.dart';

class MatchesHeaderViewSwitch extends StatelessWidget {
  const MatchesHeaderViewSwitch({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final MatchesViewMode selected;
  final ValueChanged<MatchesViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sportForeground(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.sportForeground(context).withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            HeaderSwitchIcon(
              icon: FIcons.list,
              selected: selected == MatchesViewMode.list,
              onTap: () => onChanged(MatchesViewMode.list),
            ),
            HeaderSwitchIcon(
              icon: FIcons.calendarDays,
              selected: selected == MatchesViewMode.calendar,
              onTap: () => onChanged(MatchesViewMode.calendar),
            ),
          ],
        ),
      ),
    );
  }
}
