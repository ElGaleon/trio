import 'package:flutter/material.dart';

import 'package:trio/src/constants/app_constants.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';

import 'custom_stat.dart';

class AppSettings {
  AppSettings({
    this.themeModeIndex = 0,
    this.eloKFactor = AppConstants.eloKFactor,
    this.initialRating = AppConstants.initialRating,
    Map<MatchStatType, double>? statWeights,
    List<CustomStat>? customStats,
    Set<String>? favoriteStatNames,
  }) : statWeights = {...defaultStatWeights, ...?statWeights},
       customStats = customStats ?? [],
       favoriteStatNames =
           favoriteStatNames ??
           MatchStatType.defaultEnabled.map((t) => t.name).toSet();

  int themeModeIndex;
  double eloKFactor;
  double initialRating;
  Map<MatchStatType, double> statWeights;
  List<CustomStat> customStats;
  Set<String> favoriteStatNames;

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

  double customStatWeightFor(String id) {
    for (final stat in customStats) {
      if (stat.id == id) return stat.weight;
    }
    return 0.0;
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
    List<CustomStat>? customStats,
    Set<String>? favoriteStatNames,
  }) {
    return AppSettings(
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      eloKFactor: eloKFactor ?? this.eloKFactor,
      initialRating: initialRating ?? this.initialRating,
      statWeights: statWeights ?? {...this.statWeights},
      customStats: customStats ?? [...this.customStats],
      favoriteStatNames: favoriteStatNames ?? {...this.favoriteStatNames},
    );
  }
}
