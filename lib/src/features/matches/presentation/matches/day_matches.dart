import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/src/shared/app_empty_state.dart';
import 'package:trio/src/shared/match_card.dart';
import 'package:trio/src/features/events/domain/team_event.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'calendar_utils.dart';

class DayMatches extends StatelessWidget {
  const DayMatches({
    super.key,
    required this.selectedDay,
    required this.matches,
    required this.events,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime? selectedDay;
  final List<ScrimmageMatch> matches;
  final List<TeamEvent> events;
  final void Function(ScrimmageMatch match)? onEdit;
  final void Function(ScrimmageMatch match)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) return const SizedBox.shrink();
    final matchEventIds = {
      for (final match in matches) ...[
        if (match.eventId != null) match.eventId!,
        if (match.trainingEventId != null) match.trainingEventId!,
      ],
    };
    final scheduledEvents = events.where((event) {
      final playable =
          event.type == TeamEventType.training || event.type.isMatch;
      return playable && !matchEventIds.contains(event.storageId);
    }).toList();

    if (matches.isEmpty && scheduledEvents.isEmpty) {
      return SportEmptyState(
        icon: FIcons.calendarX,
        title: 'Nessun match',
        message:
            'Non ci sono partite il ${CalendarUtils.dayLabel(selectedDay!)}.',
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
              color: AppColors.sportForeground(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        for (final event in scheduledEvents) _ScheduledEventCard(event: event),
        for (final match in matches)
          MatchCard(
            match: match,
            planned: match.eventId != null || match.trainingEventId != null,
            onTap: () => context.go(AppRoutes.matchDetail(match.id)),
            onEdit: onEdit == null ? null : () => onEdit!(match),
            onDelete: onDelete == null ? null : () => onDelete!(match),
          ),
      ],
    );
  }
}

class _ScheduledEventCard extends StatelessWidget {
  const _ScheduledEventCard({required this.event});

  final TeamEvent event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final time =
        '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';

    return Material(
      color: AppColors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.65)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            spacing: 12,
            children: [
              Icon(Icons.event_available_outlined, color: AppColors.danger),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      event.title.isEmpty ? event.type.label : event.title,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.sportForeground(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Prevista alle $time${event.location.isEmpty ? '' : ' · ${event.location}'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.sportMutedForeground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              FBadge(child: Text('Prevista')),
            ],
          ),
        ),
      ),
    );
  }
}
