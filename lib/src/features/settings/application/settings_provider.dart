import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trio/src/features/auth/application/rbac_provider.dart';
import 'package:trio/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/players/application/player_providers.dart';
import 'package:trio/src/features/settings/domain/app_settings.dart';
import 'package:trio/src/features/settings/domain/settings_form_state.dart';

import 'package:trio/src/features/settings/domain/custom_stat.dart';

class SettingsFormNotifier extends Notifier<SettingsFormState> {
  @override
  SettingsFormState build() {
    final settings = ref.read(appSettingsProvider);
    return SettingsFormState(
      themeModeIndex: settings.themeModeIndex,
      eloKFactor: settings.eloKFactor.round().toString(),
      initialRating: settings.initialRating.round().toString(),
      statWeights: {
        for (final entry in AppSettings.defaultStatWeights.entries)
          entry.key.name: settings.statWeightFor(entry.key).toString(),
      },
      customStats: settings.customStats,
      favoriteStatNames: settings.favoriteStatNames,
    );
  }

  void updateThemeMode(int index) {
    state = state.copyWith(themeModeIndex: index);
  }

  void updateEloKFactor(String value) {
    state = state.copyWith(eloKFactor: value);
  }

  void updateInitialRating(String value) {
    state = state.copyWith(initialRating: value);
  }

  void updateStatWeight(MatchStatType type, String value) {
    state = state.copyWith(
      statWeights: {...state.statWeights, type.name: value},
    );
  }

  void addCustomStat(CustomStat stat) {
    state = state.copyWith(customStats: [...state.customStats, stat]);
  }

  void updateCustomStat(CustomStat stat) {
    state = state.copyWith(
      customStats: state.customStats
          .map((s) => s.id == stat.id ? stat : s)
          .toList(),
    );
  }

  void removeCustomStat(String id) {
    state = state.copyWith(
      customStats: state.customStats.where((s) => s.id != id).toList(),
      favoriteStatNames: state.favoriteStatNames
          .where((name) => name != id)
          .toSet(),
    );
  }

  void toggleFavoriteStat(String name) {
    final favorites = {...state.favoriteStatNames};
    if (favorites.contains(name)) {
      favorites.remove(name);
    } else {
      favorites.add(name);
    }
    state = state.copyWith(favoriteStatNames: favorites);
  }

  Future<bool> save() async {
    if (!can(ref.read(currentRoleProvider), AppPermission.editSettings)) {
      return false;
    }
    final eloKFactorVal = double.tryParse(state.eloKFactor.trim());
    final initialRatingVal = double.tryParse(state.initialRating.trim());
    final statWeights = <MatchStatType, double>{};
    for (final entry in AppSettings.defaultStatWeights.entries) {
      final value = double.tryParse(state.statWeights[entry.key.name] ?? '');
      if (value == null) return false;
      statWeights[entry.key] = value;
    }

    if (eloKFactorVal == null ||
        initialRatingVal == null ||
        eloKFactorVal <= 0 ||
        initialRatingVal <= 0) {
      return false;
    }

    final settings = AppSettings(
      themeModeIndex: state.themeModeIndex,
      eloKFactor: eloKFactorVal,
      initialRating: initialRatingVal,
      statWeights: statWeights,
      customStats: state.customStats,
      favoriteStatNames: state.favoriteStatNames,
    );

    final repository = ref.read(firestoreTrioRepositoryProvider);
    if (repository == null) return false;
    await repository.saveSettings(settings);
    ref.invalidate(appSettingsProvider);
    return true;
  }
}

final settingsFormProvider =
    NotifierProvider.autoDispose<SettingsFormNotifier, SettingsFormState>(
      SettingsFormNotifier.new,
    );
