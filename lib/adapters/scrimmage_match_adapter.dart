import 'package:hive/hive.dart';

import '../app_constants.dart';
import '../models/scrimmage_match.dart';

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
    );
  }

  @override
  void write(BinaryWriter writer, ScrimmageMatch obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.teamBName);
  }
}
