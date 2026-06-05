import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'adapters/app_settings_adapter.dart';
import 'adapters/player_adapter.dart';
import 'adapters/scrimmage_match_adapter.dart';
import 'app_constants.dart';
import 'app_router.dart';
import 'model/app_settings.dart';
import 'model/player.dart';
import 'model/scrimmage_match.dart';
import 'providers/elo_providers.dart';
import 'theme/app_colors.dart';

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
    final themeMode = switch (settings.themeModeIndex) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      routerConfig: appRouter,
      builder: (context, child) {
        return FTheme(data: FThemes.violet.dark.touch, child: child!);
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? AppColors.appDarkBackground
        : AppColors.appLightBackground;
    final surface = isDark
        ? AppColors.appDarkSurface
        : AppColors.appLightSurface;
    final border = isDark
        ? AppColors.appDarkElevated
        : AppColors.appLightBorder;
    final foreground = isDark
        ? AppColors.appDarkForeground
        : AppColors.appLightForeground;
    const accent = AppColors.violet;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: AppColors.white,
          secondary: AppColors.violetHover,
          tertiary: accent,
          surface: surface,
          onSurface: foreground,
          surfaceContainerHighest: isDark
              ? AppColors.appDarkElevated
              : AppColors.violetSoft,
          outline: border,
          outlineVariant: border,
        );

    return ThemeData(
      colorScheme: colorScheme,
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
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        headerBackgroundColor: accent,
        headerForegroundColor: AppColors.white,
        todayForegroundColor: WidgetStateProperty.all(accent),
        todayBorder: BorderSide(color: accent),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return foreground;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return null;
        }),
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
        foregroundColor: AppColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.violetDarkSoft : accent,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
