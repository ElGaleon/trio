import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skrim/src/features/settings/application/theme_mode_provider.dart';

void main() {
  test('loads the theme mode from shared preferences', () async {
    SharedPreferences.setMockInitialValues({
      'themeModeIndex': ThemeMode.light.index,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('saves the selected theme mode in shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeModeIndexProvider.notifier).set(ThemeMode.dark.index);
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('themeModeIndex'), ThemeMode.dark.index);
  });
}
