import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/app_constants.dart';
import 'features/settings/application/theme_mode_provider.dart';
import 'routing/app_router.dart';
import '../theme/app_colors.dart';

class ScrimApp extends ConsumerWidget {
  const ScrimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      routerConfig: appRouter,
      builder: (context, child) {
        return AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: FTheme(data: FThemes.violet.dark.touch, child: child!),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final palette = AppColorPalette.forBrightness(brightness);
    final isDark = brightness == Brightness.dark;
    final background = palette.background;
    final surface = palette.surface;
    final border = palette.border;
    final foreground = palette.foreground;
    final accent = palette.violet;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: palette.onColor,
          secondary: palette.violetHover,
          tertiary: accent,
          surface: surface,
          onSurface: foreground,
          surfaceContainerHighest: palette.elevated,
          outline: border,
          outlineVariant: border,
        );
    final textTheme = _buildTextTheme(brightness, foreground);

    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: false,
      extensions: [palette],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
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
        headerForegroundColor: palette.onColor,
        todayForegroundColor: WidgetStateProperty.all(accent),
        todayBorder: BorderSide(color: accent),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.onColor;
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
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        color: surface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: palette.onColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: palette.onColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? palette.violetDarkSoft : accent,
        contentTextStyle: TextStyle(
          color: palette.onColor,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }

  TextTheme _buildTextTheme(Brightness brightness, Color foreground) {
    final base = brightness == Brightness.dark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;
    final textTheme = GoogleFonts.barlowSemiCondensedTextTheme(
      base.apply(bodyColor: foreground, displayColor: foreground),
    );

    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ),
      displayMedium: textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ),
      displaySmall: textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ),
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      labelMedium: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      labelSmall: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
