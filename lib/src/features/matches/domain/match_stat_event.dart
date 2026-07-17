import 'match_stat_type.dart';

class MatchStatEvent {
  const MatchStatEvent({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.pointNumber,
    required this.scoreA,
    required this.scoreB,
    required this.oursOnOffense,
    this.playerId,
    this.discHolderId,
    this.lineupIds = const [],
    this.description,
    this.pullDurationSeconds,
    this.pullInBounds,
    this.statValue,
    this.customStatId,
  });

  final String id;
  final MatchStatType type;
  final DateTime createdAt;
  final int pointNumber;
  final int scoreA;
  final int scoreB;
  final bool oursOnOffense;
  final String? playerId;
  final String? discHolderId;
  final List<String> lineupIds;
  final String? description;
  final int? pullDurationSeconds;
  final bool? pullInBounds;
  final double? statValue;
  final String? customStatId;

  bool get isGoal => type == MatchStatType.goal;
  bool get isError => type.isError;
  bool get isCompletedPass =>
      type == MatchStatType.pass || type == MatchStatType.huck;
  bool get isThrowError => type == MatchStatType.throwError;
  bool get isCatchError => type == MatchStatType.catchError;
  bool get isAttemptedPass => isCompletedPass || isThrowError || isCatchError;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'createdAt': createdAt,
      'pointNumber': pointNumber,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'oursOnOffense': oursOnOffense,
      'playerId': playerId,
      'discHolderId': discHolderId,
      'lineupIds': lineupIds,
      'description': description,
      'pullDurationSeconds': pullDurationSeconds,
      'pullInBounds': pullInBounds,
      'statValue': statValue,
      'customStatId': customStatId,
    };
  }

  static MatchStatEvent fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type'] as String? ?? MatchStatType.pass.name;
    return MatchStatEvent(
      id:
          map['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: MatchStatType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => MatchStatType.pass,
      ),
      createdAt: map['createdAt'] as DateTime? ?? DateTime.now(),
      pointNumber: map['pointNumber'] as int? ?? 1,
      scoreA: map['scoreA'] as int? ?? 0,
      scoreB: map['scoreB'] as int? ?? 0,
      oursOnOffense: map['oursOnOffense'] as bool? ?? true,
      playerId: map['playerId'] as String?,
      discHolderId: map['discHolderId'] as String?,
      lineupIds: List<String>.from(map['lineupIds'] as List? ?? []),
      description: map['description'] as String?,
      pullDurationSeconds: map['pullDurationSeconds'] as int?,
      pullInBounds: map['pullInBounds'] as bool?,
      statValue: (map['statValue'] as num?)?.toDouble(),
      customStatId: map['customStatId'] as String?,
    );
  }
}
