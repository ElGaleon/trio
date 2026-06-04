import 'package:hive/hive.dart';

import '../app_constants.dart';
import '../models/player.dart';

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = AppConstants.playerTypeId;

  @override
  Player read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    final linePreference = _readLinePreference(fields[6]);
    final role = _readRole(fields[7]);
    final profileImagePath = fields[8] as String?;
    final isExternal = fields[9] as bool? ?? false;
    return Player(
      id: fields[0] as String,
      name: fields[1] as String,
      rating: fields[2] as double? ?? AppConstants.initialRating,
      matchesPlayed: fields[3] as int? ?? 0,
      wins: fields[4] as int? ?? 0,
      losses: fields[5] as int? ?? 0,
      linePreference: linePreference,
      role: role,
      profileImagePath: profileImagePath?.trim().isEmpty ?? true
          ? null
          : profileImagePath,
      isExternal: isExternal,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.rating)
      ..writeByte(3)
      ..write(obj.matchesPlayed)
      ..writeByte(4)
      ..write(obj.wins)
      ..writeByte(5)
      ..write(obj.losses)
      ..writeByte(6)
      ..write(obj.linePreference.index)
      ..writeByte(7)
      ..write(obj.role.index)
      ..writeByte(8)
      ..write(obj.profileImagePath)
      ..writeByte(9)
      ..write(obj.isExternal);
  }

  PlayerLinePreference _readLinePreference(Object? value) {
    if (value is int &&
        value >= 0 &&
        value < PlayerLinePreference.values.length) {
      return PlayerLinePreference.values[value];
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized.contains('offense') ||
          normalized.contains('offence') ||
          normalized.contains('attacco')) {
        return PlayerLinePreference.offense;
      }
      if (normalized.contains('defense') ||
          normalized.contains('defence') ||
          normalized.contains('difesa')) {
        return PlayerLinePreference.defense;
      }
    }
    return PlayerLinePreference.offense;
  }

  PlayerRole _readRole(Object? value) {
    if (value is int && value >= 0 && value < PlayerRole.values.length) {
      return PlayerRole.values[value];
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized.contains('handler')) return PlayerRole.handler;
      if (normalized.contains('cutter')) return PlayerRole.cutter;
    }
    return PlayerRole.cutter;
  }
}
