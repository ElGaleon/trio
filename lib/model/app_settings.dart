import 'package:flutter/material.dart';

import '../app_constants.dart';
import 'scrimmage_match.dart';

class AppSettings {
  AppSettings({
    this.themeModeIndex = 0,
    this.eloKFactor = AppConstants.eloKFactor,
    this.initialRating = AppConstants.initialRating,
    Map<MatchStatType, double>? statWeights,
  }) : statWeights = {...defaultStatWeights, ...?statWeights};

  int themeModeIndex;
  double eloKFactor;
  double initialRating;
  Map<MatchStatType, double> statWeights;

  static Map<MatchStatType, double> get defaultStatWeights => {
    MatchStatType.goal: 3,
    MatchStatType.assist: 2,
    MatchStatType.defense: 2,
    MatchStatType.block: 2,
    MatchStatType.pass: 0.2,
    MatchStatType.huck: 0.4,
    MatchStatType.catchDisc: 0.2,
    MatchStatType.pull: 0.8,
    MatchStatType.opponentError: 0.5,
    MatchStatType.throwError: -2,
    MatchStatType.catchError: -1.5,
    MatchStatType.stallOut: -2,
    MatchStatType.openError: -1,
    MatchStatType.deepError: -1,
    MatchStatType.resetError: -1,
    MatchStatType.opponentGoal: -1,
  };

  double statWeightFor(MatchStatType type) {
    return statWeights[type] ?? defaultStatWeights[type] ?? 0;
  }

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
    Map<MatchStatType, double>? statWeights,
  }) {
    return AppSettings(
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      eloKFactor: eloKFactor ?? this.eloKFactor,
      initialRating: initialRating ?? this.initialRating,
      statWeights: statWeights ?? {...this.statWeights},
    );
  }
}
