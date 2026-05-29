import 'package:hive/hive.dart';

import '../app_constants.dart';
import '../models/app_settings.dart';

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
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.themeModeIndex)
      ..writeByte(1)
      ..write(obj.eloKFactor)
      ..writeByte(2)
      ..write(obj.initialRating);
  }
}
