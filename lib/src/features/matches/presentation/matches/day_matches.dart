import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/src/common_widgets/app_empty_state.dart';
import 'package:trio/src/common_widgets/match_card.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'calendar_utils.dart';

class DayMatches extends StatelessWidget {
  const DayMatches({
    super.key,
    required this.selectedDay,
    required this.matches,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime? selectedDay;
  final List<ScrimmageMatch> matches;
  final void Function(ScrimmageMatch match) onEdit;
  final void Function(ScrimmageMatch match) onDelete;

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) return const SizedBox.shrink();
    if (matches.isEmpty) {
      return SportEmptyState(
        icon: FIcons.calendarX,
        title: 'Nessun match',
        message: 'Non ci sono partite il ${CalendarUtils.dayLabel(selectedDay!)}.',
      );
    }
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            CalendarUtils.dayLabel(selectedDay!),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        for (final match in matches)
          MatchCard(
            match: match,
            onTap: () => context.go(AppRoutes.matchDetail(match.id)),
            onEdit: () => onEdit(match),
            onDelete: () => onDelete(match),
          ),
      ],
    );
  }
}
