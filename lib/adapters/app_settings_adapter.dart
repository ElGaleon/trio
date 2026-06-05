import 'package:hive/hive.dart';

import '../app_constants.dart';
import '../model/app_settings.dart';
import '../model/scrimmage_match.dart';

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = AppConstants.settingsTypeId;

  @override
  AppSettings read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      themeModeIndex: fields[0] as int? ?? 0,
      eloKFactor: fields[1] as double? ?? AppConstants.eloKFactor,
      initialRating: fields[2] as double? ?? AppConstants.initialRating,
      statWeights: _readStatWeights(fields[3]),
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.themeModeIndex)
      ..writeByte(1)
      ..write(obj.eloKFactor)
      ..writeByte(2)
      ..write(obj.initialRating)
      ..writeByte(3)
      ..write(obj.statWeights.map((key, value) => MapEntry(key.name, value)));
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
