import 'match_stat_type.dart';

class LivePendingAction {
  const LivePendingAction({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.createdByUserId,
    required this.createdByLabel,
    required this.confirmedByUserIds,
    this.statType,
    this.teamAIds = const [],
    this.teamBIds = const [],
    this.nextOnOffense,
  });

  final String id;
  final String kind;
  final DateTime createdAt;
  final String createdByUserId;
  final String createdByLabel;
  final List<String> confirmedByUserIds;
  final MatchStatType? statType;
  final List<String> teamAIds;
  final List<String> teamBIds;
  final bool? nextOnOffense;

  bool confirmedBy(String userId) => confirmedByUserIds.contains(userId);

  LivePendingAction confirm(String userId) {
    if (confirmedBy(userId)) return this;
    return LivePendingAction(
      id: id,
      kind: kind,
      createdAt: createdAt,
      createdByUserId: createdByUserId,
      createdByLabel: createdByLabel,
      confirmedByUserIds: [...confirmedByUserIds, userId],
      statType: statType,
      teamAIds: teamAIds,
      teamBIds: teamBIds,
      nextOnOffense: nextOnOffense,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kind': kind,
      'createdAt': createdAt.toUtc(),
      'createdByUserId': createdByUserId,
      'createdByLabel': createdByLabel,
      'confirmedByUserIds': confirmedByUserIds,
      'statType': statType?.name,
      'teamAIds': teamAIds,
      'teamBIds': teamBIds,
      'nextOnOffense': nextOnOffense,
    };
  }

  static LivePendingAction? fromMap(Object? value) {
    if (value is! Map) return null;
    final statTypeName = value['statType'] as String?;
    return LivePendingAction(
      id: value['id'] as String? ?? '',
      kind: value['kind'] as String? ?? '',
      createdAt: _dateFrom(value['createdAt']) ?? DateTime.now(),
      createdByUserId: value['createdByUserId'] as String? ?? '',
      createdByLabel: value['createdByLabel'] as String? ?? 'Utente',
      confirmedByUserIds: List<String>.from(
        value['confirmedByUserIds'] as List? ?? [],
      ),
      statType: statTypeName == null
          ? null
          : MatchStatType.values.firstWhere(
              (type) => type.name == statTypeName,
              orElse: () => MatchStatType.pass,
            ),
      teamAIds: List<String>.from(value['teamAIds'] as List? ?? []),
      teamBIds: List<String>.from(value['teamBIds'] as List? ?? []),
      nextOnOffense: value['nextOnOffense'] as bool?,
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
