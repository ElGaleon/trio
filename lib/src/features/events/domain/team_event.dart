enum TeamEventType { other, officialMatch, friendlyMatch, training }

enum TeamEventRecurrence { none, weekly, monthly }

extension TeamEventRecurrenceLabel on TeamEventRecurrence {
  String get label => switch (this) {
    TeamEventRecurrence.none => 'Non ricorrente',
    TeamEventRecurrence.weekly => 'Ogni settimana',
    TeamEventRecurrence.monthly => 'Ogni mese',
  };
}

extension TeamEventTypeLabel on TeamEventType {
  String get label => switch (this) {
    TeamEventType.other => 'Altro',
    TeamEventType.officialMatch => 'Match ufficiale',
    TeamEventType.friendlyMatch => 'Amichevole',
    TeamEventType.training => 'Allenamento',
  };

  bool get isMatch =>
      this == TeamEventType.officialMatch ||
      this == TeamEventType.friendlyMatch;
}

class TeamEvent {
  const TeamEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.location,
    this.notes = '',
    this.type = TeamEventType.other,
    this.matchIds = const [],
    this.presentPlayerIds = const [],
    this.recurrence = TeamEventRecurrence.none,
    this.recurrenceEndsAt,
    this.sourceEventId,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String notes;
  final TeamEventType type;
  final List<String> matchIds;
  final List<String> presentPlayerIds;
  final TeamEventRecurrence recurrence;
  final DateTime? recurrenceEndsAt;
  final String? sourceEventId;

  String get storageId => sourceEventId ?? id;

  TeamEvent copyWith({
    String? id,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    String? notes,
    TeamEventType? type,
    List<String>? matchIds,
    List<String>? presentPlayerIds,
    TeamEventRecurrence? recurrence,
    DateTime? recurrenceEndsAt,
    bool clearRecurrenceEndsAt = false,
    String? sourceEventId,
  }) {
    return TeamEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      matchIds: matchIds ?? this.matchIds,
      presentPlayerIds: presentPlayerIds ?? this.presentPlayerIds,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndsAt: clearRecurrenceEndsAt
          ? null
          : recurrenceEndsAt ?? this.recurrenceEndsAt,
      sourceEventId: sourceEventId ?? this.sourceEventId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startAt': startAt.toUtc(),
      'endAt': endAt.toUtc(),
      'location': location,
      'notes': notes,
      'type': type.name,
      'matchIds': matchIds,
      'presentPlayerIds': presentPlayerIds,
      'recurrence': recurrence.name,
      'recurrenceEndsAt': recurrenceEndsAt?.toUtc(),
    };
  }

  static TeamEvent fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type'] as String? ?? '';
    final recurrenceName = map['recurrence'] as String? ?? '';
    return TeamEvent(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      startAt: _dateFrom(map['startAt']) ?? DateTime.now(),
      endAt: _dateFrom(map['endAt']) ?? DateTime.now(),
      location: map['location'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      type: TeamEventType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => TeamEventType.other,
      ),
      matchIds: List<String>.from(map['matchIds'] as List? ?? []),
      presentPlayerIds: List<String>.from(
        map['presentPlayerIds'] as List? ?? [],
      ),
      recurrence: TeamEventRecurrence.values.firstWhere(
        (recurrence) => recurrence.name == recurrenceName,
        orElse: () => TeamEventRecurrence.none,
      ),
      recurrenceEndsAt: _dateFrom(map['recurrenceEndsAt']),
    );
  }
}

DateTime? _dateFrom(Object? value) {
  if (value is DateTime) return value;
  try {
    final dynamic candidate = value;
    final date = candidate?.toDate();
    if (date is DateTime) return date;
  } catch (_) {
    return null;
  }
  return null;
}
