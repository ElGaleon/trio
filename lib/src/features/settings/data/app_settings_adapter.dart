import 'package:hive/hive.dart';

import 'package:trio/src/constants/app_constants.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/settings/domain/app_settings.dart';

import '../domain/custom_stat.dart';

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = AppConstants.settingsTypeId;

  @override
  AppSettings read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    
    final customStatsRaw = fields[4] as List?;
    final customStats = customStatsRaw != null
        ? customStatsRaw.map((map) => CustomStat.fromMap(map as Map)).toList()
        : <CustomStat>[];
        
    final favoriteStatNamesRaw = fields[5] as List?;
    final favoriteStatNames = favoriteStatNamesRaw?.cast<String>().toSet();

    return AppSettings(
      themeModeIndex: fields[0] as int? ?? 0,
      eloKFactor: fields[1] as double? ?? AppConstants.eloKFactor,
      initialRating: fields[2] as double? ?? AppConstants.initialRating,
      statWeights: _readStatWeights(fields[3]),
      customStats: customStats,
      favoriteStatNames: favoriteStatNames,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.themeModeIndex)
      ..writeByte(1)
      ..write(obj.eloKFactor)
      ..writeByte(2)
      ..write(obj.initialRating)
      ..writeByte(3)
      ..write(obj.statWeights.map((key, value) => MapEntry(key.name, value)))
      ..writeByte(4)
      ..write(obj.customStats.map((s) => s.toMap()).toList())
      ..writeByte(5)
      ..write(obj.favoriteStatNames.toList());
  }

  Map<MatchStatType, double>? _readStatWeights(dynamic value) {
    if (value is! Map) return null;
    final weights = <MatchStatType, double>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final rawValue = entry.value;
      if (key is! String || rawValue is! num) continue;
      for (final type in MatchStatType.values) {
        if (type.name == key) {
          weights[type] = rawValue.toDouble();
          break;
        }
      }
    }
    return weights;
  }
}
