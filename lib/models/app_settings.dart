import 'package:flutter/material.dart';

import '../app_constants.dart';

class AppSettings {
  AppSettings({
    this.themeModeIndex = 0,
    this.eloKFactor = AppConstants.eloKFactor,
    this.initialRating = AppConstants.initialRating,
  });

  int themeModeIndex;
  double eloKFactor;
  double initialRating;

  ThemeMode get themeMode {
    return switch (themeModeIndex) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  AppSettings copyWith({
    int? themeModeIndex,
    double? eloKFactor,
    double? initialRating,
  }) {
    return AppSettings(
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      eloKFactor: eloKFactor ?? this.eloKFactor,
      initialRating: initialRating ?? this.initialRating,
    );
  }
}
