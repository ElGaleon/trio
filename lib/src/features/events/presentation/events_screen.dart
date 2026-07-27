import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:skrim/src/features/auth/application/rbac_provider.dart';
import 'package:skrim/src/features/events/application/events_providers.dart';
import 'package:skrim/src/features/events/domain/team_event.dart';
import 'package:skrim/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:skrim/src/features/matches/presentation/matches/calendar_utils.dart';
import 'package:skrim/src/routing/app_router.dart';
import 'package:skrim/src/shared/app_empty_state.dart';
import 'package:skrim/src/shared/decorated_panel.dart';
import 'package:skrim/src/shared/sport_button.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/theme/app_colors.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final canView = can(role, AppPermission.viewEvents);
    final canCreate = can(role, AppPermission.createEvent);
    final canEdit = can(role, AppPermission.editEvent);
    final canDelete = can(role, AppPermission.deleteEvent);

    if (!canView) {
      return const SportScreenShell(
        title: 'Calendario',
        subtitle: 'Eventi',
        child: SportEmptyState(
          icon: Icons.lock_outline,
          title: 'Sezione non disponibile',
          message: 'Il calendario eventi non è disponibile.',
        ),
      );
    }

    final repository = ref.watch(firestoreSkrimRepositoryProvider);
    final events = ref.watch(eventsProvider);
    final selectedDay = ref.watch(eventsSelectedDayProvider);
    final viewMode = ref.watch(eventsViewModeProvider);

    return SportScreenShell(
      title: 'Calendario',
      subtitle: 'Eventi e presenze richieste',
      headerActions: [
        _ViewSwitch(
          selected: viewMode,
          onChanged: (mode) =>
              ref.read(eventsViewModeProvider.notifier).set(mode),
        ),
      ],
      floatingActionButton: canCreate
          ? SportFloatingActionButton(
              label: 'Nuovo',
              icon: Icons.add,
              onPressed: () => _showEventDialog(context, ref),
            )
          : null,
      child: Column(
        spacing: 14,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PeriodHeader(
            selectedDay: selectedDay,
            viewMode: viewMode,
            onPrevious: () => _move(ref, viewMode, -1),
            onNext: () => _move(ref, viewMode, 1),
            onToday: () {
              final now = DateTime.now();
              ref
                  .read(eventsSelectedDayProvider.notifier)
                  .set(DateTime(now.year, now.month, now.day));
            },
          ),
          if (events.isEmpty)
            const SportEmptyState(
              icon: Icons.event_available_outlined,
              title: 'Nessun evento',
              message: 'Crea il primo evento del calendario.',
            )
          else
            switch (viewMode) {
              EventsViewMode.list => _EventList(
                events: events,
                onEdit: canEdit
                    ? (event) => _showEventDialog(context, ref, event)
                    : null,
                onDelete: canDelete
                    ? (event) => repository?.deleteEvent(event.storageId)
                    : null,
              ),
              EventsViewMode.day => _EventList(
                events: ref.watch(selectedDayEventsProvider),
                emptyMessage: 'Non ci sono eventi in questo giorno.',
                onEdit: canEdit
                    ? (event) => _showEventDialog(context, ref, event)
                    : null,
                onDelete: canDelete
                    ? (event) => repository?.deleteEvent(event.storageId)
                    : null,
              ),
              EventsViewMode.week => _WeekView(
                events: events,
                selectedDay: selectedDay,
                onSelect: (day) =>
                    ref.read(eventsSelectedDayProvider.notifier).set(day),
                onEdit: canEdit
                    ? (event) => _showEventDialog(context, ref, event)
                    : null,
                onDelete: canDelete
                    ? (event) => repository?.deleteEvent(event.storageId)
                    : null,
              ),
              EventsViewMode.month => _MonthView(
                events: events,
                selectedDay: selectedDay,
                onSelect: (day) =>
                    ref.read(eventsSelectedDayProvider.notifier).set(day),
                onEdit: canEdit
                    ? (event) => _showEventDialog(context, ref, event)
                    : null,
                onDelete: canDelete
                    ? (event) => repository?.deleteEvent(event.storageId)
                    : null,
              ),
            },
        ],
      ),
    );
  }

  void _move(WidgetRef ref, EventsViewMode mode, int direction) {
    final day = ref.read(eventsSelectedDayProvider);
    final next = switch (mode) {
      EventsViewMode.list ||
      EventsViewMode.month => DateTime(day.year, day.month + direction, 1),
      EventsViewMode.week => day.add(Duration(days: 7 * direction)),
      EventsViewMode.day => day.add(Duration(days: direction)),
    };
    ref
        .read(eventsSelectedDayProvider.notifier)
        .set(DateTime(next.year, next.month, next.day));
  }

  Future<void> _showEventDialog(
    BuildContext context,
    WidgetRef ref, [
    TeamEvent? event,
  ]) async {
    final role = ref.read(currentRoleProvider);
    final permission = event == null
        ? AppPermission.createEvent
        : AppPermission.editEvent;
    if (!can(role, permission)) return;
    final repository = ref.read(firestoreSkrimRepositoryProvider);
    if (repository == null) return;
    final saved = await showDialog<TeamEvent>(
      context: context,
      builder: (context) => _EventDialog(event: event),
    );
    if (saved == null) return;
    if (event == null) {
      await repository.addEvent(saved);
    } else {
      await repository.saveEvent(saved.copyWith(id: event.storageId));
    }
  }
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.selected, required this.onChanged});

  final EventsViewMode selected;
  final ValueChanged<EventsViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (final mode in EventsViewMode.values)
          ChoiceChip(
            label: Text(mode.label),
            selected: selected == mode,
            onSelected: (_) => onChanged(mode),
            labelStyle: TextStyle(
              color: selected == mode
                  ? AppColors.white
                  : AppColors.sportMutedText,
              fontWeight: FontWeight.w800,
            ),
            selectedColor: AppColors.violet.withValues(alpha: 0.45),
            backgroundColor: AppColors.white.withValues(alpha: 0.06),
            side: BorderSide(
              color: AppColors.sportForeground(context).withValues(alpha: 0.12),
            ),
          ),
      ],
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({
    required this.selectedDay,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime selectedDay;
  final EventsViewMode viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final label = switch (viewMode) {
      EventsViewMode.day => CalendarUtils.dayLabel(selectedDay),
      EventsViewMode.week => _weekLabel(selectedDay),
      EventsViewMode.month || EventsViewMode.list =>
        '${CalendarUtils.monthLabel(selectedDay)} ${selectedDay.year}',
    };

    return DecoratedPanel(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            FButton(
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              onPress: onPrevious,
              child: Icon(
                FIcons.chevronLeft,
                color: AppColors.sportForeground(context),
              ),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.sportForeground(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FButton(
              variant: FButtonVariant.outline,
              size: FButtonSizeVariant.sm,
              onPress: onToday,
              child: const Text('Oggi'),
            ),
            FButton(
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              onPress: onNext,
              child: Icon(
                FIcons.chevronRight,
                color: AppColors.sportForeground(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekLabel(DateTime day) {
    final start = day.subtract(Duration(days: day.weekday - DateTime.monday));
    final end = start.add(const Duration(days: 6));
    return '${CalendarUtils.dayLabel(start)} - ${CalendarUtils.dayLabel(end)}';
  }
}

class _MonthView extends ConsumerWidget {
  const _MonthView({
    required this.events,
    required this.selectedDay,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TeamEvent> events;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<TeamEvent>? onEdit;
  final ValueChanged<TeamEvent>? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = DateTime(selectedDay.year, selectedDay.month);
    final days = CalendarUtils.calendarDays(month);

    return Column(
      spacing: 14,
      children: [
        DecoratedPanel(
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final label in const [
                      'Lun',
                      'Mar',
                      'Mer',
                      'Gio',
                      'Ven',
                      'Sab',
                      'Dom',
                    ])
                      Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.sportMutedForeground(
                                    context,
                                  ),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  itemCount: days.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final dayEvents = eventsInRange(
                      events,
                      DateTime(day.year, day.month, day.day),
                      DateTime(day.year, day.month, day.day + 1),
                    );
                    final selected = sameEventDay(day, selectedDay);
                    final inMonth = day.month == selectedDay.month;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(day),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.violet.withValues(alpha: 0.42)
                              : AppColors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.violet
                                : AppColors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: AppColors.sportForeground(
                                    context,
                                  ).withValues(alpha: inMonth ? 1 : 0.38),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              if (dayEvents.isNotEmpty)
                                Text(
                                  '${dayEvents.length} eventi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.sportForeground(
                                          context,
                                        ),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        _EventList(
          events: ref.watch(selectedDayEventsProvider),
          emptyMessage: 'Non ci sono eventi nel giorno selezionato.',
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.events,
    required this.selectedDay,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TeamEvent> events;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<TeamEvent>? onEdit;
  final ValueChanged<TeamEvent>? onDelete;

  @override
  Widget build(BuildContext context) {
    final start = selectedDay.subtract(
      Duration(days: selectedDay.weekday - DateTime.monday),
    );
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];

    return Column(
      spacing: 10,
      children: [
        for (final day in days)
          _DayStrip(
            day: day,
            selected: sameEventDay(day, selectedDay),
            events: eventsInRange(
              events,
              DateTime(day.year, day.month, day.day),
              DateTime(day.year, day.month, day.day + 1),
            ),
            onSelect: () => onSelect(day),
            onEdit: onEdit,
            onDelete: onDelete,
          ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.day,
    required this.selected,
    required this.events,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime day;
  final bool selected;
  final List<TeamEvent> events;
  final VoidCallback onSelect;
  final ValueChanged<TeamEvent>? onEdit;
  final ValueChanged<TeamEvent>? onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedPanel(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSelect,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${_weekday(day)} ${CalendarUtils.dayLabel(day)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? AppColors.violet : AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (events.isEmpty)
              Text(
                'Nessun evento',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.sportMutedForeground(context),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              for (final event in events)
                _EventTile(event: event, onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.events,
    required this.onEdit,
    required this.onDelete,
    this.emptyMessage = 'Non ci sono eventi da mostrare.',
  });

  final List<TeamEvent> events;
  final ValueChanged<TeamEvent>? onEdit;
  final ValueChanged<TeamEvent>? onDelete;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return SportEmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Nessun evento',
        message: emptyMessage,
      );
    }

    return Column(
      spacing: 10,
      children: [
        for (final event in events)
          _EventTile(event: event, onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final TeamEvent event;
  final ValueChanged<TeamEvent>? onEdit;
  final ValueChanged<TeamEvent>? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedMatches = ref.watch(eventMatchesProvider(event.storageId));
    final now = DateTime.now();
    final active = event.startAt.isBefore(now) && event.endAt.isAfter(now);
    final playable =
        active && (event.type == TeamEventType.training || event.type.isMatch);
    final liveMatch = event.type.isMatch && linkedMatches.isNotEmpty
        ? linkedMatches.where((match) => !match.isFinished).firstOrNull
        : null;

    return DecoratedPanel(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.event_available_outlined,
              color: AppColors.sportForeground(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${event.type.label} · ${CalendarUtils.dayLabel(event.startAt)}  ${_time(event.startAt)}-${_time(event.endAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedForeground(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    event.location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (event.notes.trim().isNotEmpty)
                    Text(
                      event.notes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.sportMutedForeground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    '${event.presentPlayerIds.length} presenze registrate',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedForeground(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (playable)
                    FButton(
                      variant: FButtonVariant.outline,
                      size: FButtonSizeVariant.sm,
                      mainAxisSize: MainAxisSize.min,
                      onPress: () {
                        if (liveMatch != null) {
                          context.go(AppRoutes.liveStats(liveMatch.id));
                          return;
                        }
                        final uri = Uri(
                          path: AppRoutes.newStatsMatch,
                          queryParameters: {
                            'eventId': event.storageId,
                            if (event.type == TeamEventType.training)
                              'type': 'training',
                          },
                        );
                        context.go(uri.toString());
                      },
                      child: Text(
                        liveMatch != null
                            ? 'Apri statistiche live'
                            : event.type == TeamEventType.training
                            ? 'Nuova partita training'
                            : 'Avvia statistiche',
                      ),
                    ),
                ],
              ),
            ),
            FButton(
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              onPress: onEdit == null ? null : () => onEdit!(event),
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.sportForeground(context),
              ),
            ),
            FButton(
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              onPress: onDelete == null ? null : () => onDelete!(event),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.sportForeground(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventDialog extends ConsumerStatefulWidget {
  const _EventDialog({this.event});

  final TeamEvent? event;

  @override
  ConsumerState<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends ConsumerState<_EventDialog> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late final Set<String> _presentPlayerIds;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late TeamEventType _type;
  late TeamEventRecurrence _recurrence;
  DateTime? _recurrenceEndsAt;
  bool _presenceInitialized = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final now = DateTime.now();
    _title = TextEditingController(text: event?.title ?? '');
    _location = TextEditingController(text: event?.location ?? '');
    _notes = TextEditingController(text: event?.notes ?? '');
    _date = event?.startAt ?? DateTime(now.year, now.month, now.day);
    _start = TimeOfDay.fromDateTime(event?.startAt ?? now);
    _end = TimeOfDay.fromDateTime(
      event?.endAt ?? now.add(const Duration(hours: 2)),
    );
    _type = event?.type ?? TeamEventType.other;
    _recurrence = event?.recurrence ?? TeamEventRecurrence.none;
    _recurrenceEndsAt = event?.recurrenceEndsAt;
    _presentPlayerIds = {...event?.presentPlayerIds ?? const []};
    _presenceInitialized = event != null;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(firebasePlayersProvider);
    final players = playersAsync.value ?? const [];
    if (!_presenceInitialized && playersAsync.hasValue) {
      _presentPlayerIds.addAll(players.map((player) => player.id));
      _presenceInitialized = true;
    }

    return AlertDialog(
      title: Text(widget.event == null ? 'Nuovo evento' : 'Modifica evento'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Titolo'),
                textInputAction: TextInputAction.next,
              ),
              DropdownButtonFormField<TeamEventType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo evento'),
                items: [
                  for (final type in TeamEventType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              DropdownButtonFormField<TeamEventRecurrence>(
                initialValue: _recurrence,
                decoration: const InputDecoration(labelText: 'Ricorrenza'),
                items: [
                  for (final recurrence in TeamEventRecurrence.values)
                    DropdownMenuItem(
                      value: recurrence,
                      child: Text(recurrence.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _recurrence = value);
                },
              ),
              if (_recurrence != TeamEventRecurrence.none)
                OutlinedButton.icon(
                  onPressed: _pickRecurrenceEnd,
                  icon: Icon(Icons.event_repeat_outlined),
                  label: Text(
                    _recurrenceEndsAt == null
                        ? 'Senza fine'
                        : 'Fino a ${CalendarUtils.dayLabel(_recurrenceEndsAt!)}',
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: Icon(Icons.calendar_today_outlined),
                      label: Text(CalendarUtils.dayLabel(_date)),
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(true),
                      icon: Icon(Icons.schedule),
                      label: Text('Inizio ${_start.format(context)}'),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(false),
                      icon: Icon(Icons.schedule_outlined),
                      label: Text('Fine ${_end.format(context)}'),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Luogo'),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Note'),
                minLines: 3,
                maxLines: 5,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Presenze',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (playersAsync.isLoading)
                const CircularProgressIndicator()
              else if (players.isEmpty)
                const Text('Nessun giocatore disponibile.')
              else
                for (final player in players)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _presentPlayerIds.contains(player.id),
                    title: Text(player.name),
                    onChanged: (checked) {
                      setState(() {
                        if (checked ?? false) {
                          _presentPlayerIds.add(player.id);
                        } else {
                          _presentPlayerIds.remove(player.id);
                        }
                      });
                    },
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salva')),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _save() {
    final title = _title.text.trim();
    final location = _location.text.trim();
    if (title.isEmpty || location.isEmpty) return;

    final startAt = _at(_date, _start);
    var endAt = _at(_date, _end);
    if (!endAt.isAfter(startAt)) {
      endAt = startAt.add(const Duration(hours: 1));
    }

    Navigator.pop(
      context,
      TeamEvent(
        id: widget.event?.id ?? '',
        title: title,
        startAt: startAt,
        endAt: endAt,
        location: location,
        notes: _notes.text.trim(),
        type: _type,
        matchIds: widget.event?.matchIds ?? const [],
        presentPlayerIds: _presentPlayerIds.toList()..sort(),
        recurrence: _recurrence,
        recurrenceEndsAt: _recurrence == TeamEventRecurrence.none
            ? null
            : _recurrenceEndsAt,
      ),
    );
  }

  Future<void> _pickRecurrenceEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndsAt ?? _date.add(const Duration(days: 90)),
      firstDate: _date,
      lastDate: DateTime(2100),
    );
    setState(() => _recurrenceEndsAt = picked);
  }
}

DateTime _at(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String _time(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _weekday(DateTime date) {
  const days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  return days[date.weekday - 1];
}
