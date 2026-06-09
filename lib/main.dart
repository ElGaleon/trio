import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app.dart';
import 'src/constants/app_constants.dart';
import 'src/features/settings/data/app_settings_adapter.dart';
import 'src/features/players/data/player_adapter.dart';
import 'src/features/matches/data/scrimmage_match_adapter.dart';
import 'src/features/settings/domain/app_settings.dart';
import 'src/features/players/domain/player.dart';
import 'src/features/matches/domain/scrimmage_match.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initHive();
  runApp(const ProviderScope(child: TrioApp()));
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(AppConstants.playerTypeId)) {
    Hive.registerAdapter(PlayerAdapter());
  }
  if (!Hive.isAdapterRegistered(AppConstants.matchTypeId)) {
    Hive.registerAdapter(ScrimmageMatchAdapter());
  }
  if (!Hive.isAdapterRegistered(AppConstants.settingsTypeId)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
  await Hive.openBox<Player>(AppConstants.playersBox);
  await Hive.openBox<ScrimmageMatch>(AppConstants.matchesBox);
  final settingsBox = await Hive.openBox<AppSettings>(AppConstants.settingsBox);
  await settingsBox.put(
    AppConstants.settingsKey,
    settingsBox.get(AppConstants.settingsKey, defaultValue: AppSettings()) ??
        AppSettings(),
  );
}
