import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeIndexKey = 'themeModeIndex';

final themeModeIndexProvider = NotifierProvider<ThemeModeIndexNotifier, int>(
  ThemeModeIndexNotifier.new,
);

class ThemeModeIndexNotifier extends Notifier<int> {
  bool _changedLocally = false;

  @override
  int build() {
    unawaited(_load());
    return ThemeMode.system.index;
  }

  void set(int value) {
    final normalized = _normalize(value);
    _changedLocally = true;
    state = normalized;
    unawaited(_save(normalized));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_themeModeIndexKey);
    if (!ref.mounted) return;
    if (!_changedLocally && value != null) state = _normalize(value);
  }

  Future<void> _save(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeIndexKey, _normalize(value));
  }

  int _normalize(int value) {
    return value >= 0 && value < ThemeMode.values.length
        ? value
        : ThemeMode.system.index;
  }
}

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.values[ref.watch(themeModeIndexProvider)];
});
