import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_constants.dart';
import '../model/app_settings.dart';
import '../model/scrimmage_match.dart';
import '../model/settings_form_state.dart';
import 'elo_providers.dart';

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

  Future<bool> save() async {
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

    final settingsBox = ref.read(settingsBoxProvider);
    await settingsBox.put(
      AppConstants.settingsKey,
      AppSettings(
        themeModeIndex: state.themeModeIndex,
        eloKFactor: eloKFactorVal,
        initialRating: initialRatingVal,
        statWeights: statWeights,
      ),
    );

    ref
      ..invalidate(appSettingsProvider)
      ..invalidate(eloRepositoryProvider);

    await ref.read(eloRepositoryProvider).recalculateRatings();
    return true;
  }
}

final settingsFormProvider =
    NotifierProvider.autoDispose<SettingsFormNotifier, SettingsFormState>(
      SettingsFormNotifier.new,
    );
