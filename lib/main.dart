import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trio/screens/my_home_screen.dart';

import 'adapters/app_settings_adapter.dart';
import 'adapters/player_adapter.dart';
import 'adapters/scrimmage_match_adapter.dart';
import 'app_constants.dart';
import 'models/app_settings.dart';
import 'models/player.dart';
import 'models/scrimmage_match.dart';
import 'providers/elo_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const ProviderScope(child: TrioApp()));
}

class TrioApp extends ConsumerWidget {
  const TrioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      themeMode: settings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: MyHomeScreen(),
      builder: (context, child) {
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final brightness = switch (settings.themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => platformBrightness,
        };
        return FTheme(
          data: brightness == Brightness.dark
              ? FThemes.violet.dark.touch
              : FThemes.violet.light.touch,
          child: child!,
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF09090B)
        : const Color(0xFFFAFAFA);
    final surface = isDark ? const Color(0xFF18181B) : Colors.white;
    final border = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
    final foreground = isDark
        ? const Color(0xFFFAFAFA)
        : const Color(0xFF18181B);
    const accent = AppConstants.seedColor;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.seedColor,
        brightness: brightness,
      ),
      brightness: brightness,
      useMaterial3: false,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: const Color(0xFF71717A),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
        color: surface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }
}
