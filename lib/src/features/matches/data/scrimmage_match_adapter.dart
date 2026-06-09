import 'package:hive/hive.dart';

import 'package:trio/src/constants/app_constants.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/matches/domain/match_stat_event.dart';

class ScrimmageMatchAdapter extends TypeAdapter<ScrimmageMatch> {
  @override
  final int typeId = AppConstants.matchTypeId;

  @override
  ScrimmageMatch read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return ScrimmageMatch(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      teamAIds: List<String>.from(fields[2] as List? ?? []),
      teamBIds: List<String>.from(fields[3] as List? ?? []),
      scoreA: fields[4] as int? ?? 0,
      scoreB: fields[5] as int? ?? 0,
      initialRatings: Map<String, double>.from(fields[6] as Map? ?? {}),
      finalRatings: Map<String, double>.from(fields[7] as Map? ?? {}),
      teamSize: fields[8] as int? ?? (fields[2] as List? ?? []).length,
      offenseVsDefense: fields[9] as bool? ?? false,
      teamAName: fields[10] as String?,
      teamBName: fields[11] as String?,
      isExternalOpponent: fields[12] as bool? ?? false,
      division: fields[13] is String ? fields[13] as String : 'Mixed',
      tournament: fields[14] as String? ?? '',
      matchType: fields[15] as String? ?? 'Classic',
      windKmh: fields[16] as int? ?? 0,
      pointsLimit: fields[17] as int? ?? 15,
      durationMinutes: fields[18] as int? ?? 80,
      location: fields[19] as String? ?? '',
      hasHalfTime: fields[20] as bool? ?? true,
      halfTimeSeconds: fields[21] as int? ?? 300,
      hasTimeouts: fields[22] as bool? ?? true,
      timeoutsPerTeamPerHalf: fields[23] as int? ?? 2,
      timeoutSeconds: fields[24] as int? ?? 90,
      presentPlayerIds: List<String>.from(
        fields[27] as List? ??
            {
              ...List<String>.from(fields[2] as List? ?? []),
              ...List<String>.from(fields[3] as List? ?? []),
            },
      ),
      enabledStatTypes: (fields[26] as List?)
          ?.whereType<String>()
          .map(
            (name) => MatchStatType.values.firstWhere(
              (type) => type.name == name,
              orElse: () => MatchStatType.pass,
            ),
          )
          .toList(),
      statEvents:
          ((fields[25] is List ? fields[25] as List : null) ??
                  (fields[13] is List ? fields[13] as List : null) ??
                  [])
              .whereType<Map>()
              .map(MatchStatEvent.fromMap)
              .toList(),
      teamARosterIds: List<String>.from(fields[28] as List? ?? []),
      teamBRosterIds: List<String>.from(fields[29] as List? ?? []),
      enabledCustomStatIds: List<String>.from(fields[30] as List? ?? []),
    );
  }

  @override
  void write(BinaryWriter writer, ScrimmageMatch obj) {
    writer
      ..writeByte(31)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.teamAIds)
      ..writeByte(3)
      ..write(obj.teamBIds)
      ..writeByte(4)
      ..write(obj.scoreA)
      ..writeByte(5)
      ..write(obj.scoreB)
      ..writeByte(6)
      ..write(obj.initialRatings)
      ..writeByte(7)
      ..write(obj.finalRatings)
      ..writeByte(8)
      ..write(obj.teamSize)
      ..writeByte(9)
      ..write(obj.offenseVsDefense)
      ..writeByte(10)
      ..write(obj.teamAName)
      ..writeByte(11)
      ..write(obj.teamBName)
      ..writeByte(12)
      ..write(obj.isExternalOpponent)
      ..writeByte(13)
      ..write(obj.division)
      ..writeByte(14)
      ..write(obj.tournament)
      ..writeByte(15)
      ..write(obj.matchType)
      ..writeByte(16)
      ..write(obj.windKmh)
      ..writeByte(17)
      ..write(obj.pointsLimit)
      ..writeByte(18)
      ..write(obj.durationMinutes)
      ..writeByte(19)
      ..write(obj.location)
      ..writeByte(20)
      ..write(obj.hasHalfTime)
      ..writeByte(21)
      ..write(obj.halfTimeSeconds)
      ..writeByte(22)
      ..write(obj.hasTimeouts)
      ..writeByte(23)
      ..write(obj.timeoutsPerTeamPerHalf)
      ..writeByte(24)
      ..write(obj.timeoutSeconds)
      ..writeByte(25)
      ..write(obj.statEvents.map((event) => event.toMap()).toList())
      ..writeByte(26)
      ..write(obj.enabledStatTypes.map((type) => type.name).toList())
      ..writeByte(27)
      ..write(obj.presentPlayerIds)
      ..writeByte(28)
      ..write(obj.teamARosterIds)
      ..writeByte(29)
      ..write(obj.teamBRosterIds)
      ..writeByte(30)
      ..write(obj.enabledCustomStatIds);
  }
}
