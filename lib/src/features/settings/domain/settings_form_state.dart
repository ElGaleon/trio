import 'custom_stat.dart';

class SettingsFormState {
  final int themeModeIndex;
  final String eloKFactor;
  final String initialRating;
  final Map<String, String> statWeights;
  final List<CustomStat> customStats;
  final Set<String> favoriteStatNames;

  SettingsFormState({
    required this.themeModeIndex,
    required this.eloKFactor,
    required this.initialRating,
    required this.statWeights,
    required this.customStats,
    required this.favoriteStatNames,
  });

  SettingsFormState copyWith({
    int? themeModeIndex,
    String? eloKFactor,
    String? initialRating,
    Map<String, String>? statWeights,
    List<CustomStat>? customStats,
    Set<String>? favoriteStatNames,
  }) {
    return SettingsFormState(
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      eloKFactor: eloKFactor ?? this.eloKFactor,
      initialRating: initialRating ?? this.initialRating,
      statWeights: statWeights ?? this.statWeights,
      customStats: customStats ?? [...this.customStats],
      favoriteStatNames: favoriteStatNames ?? {...this.favoriteStatNames},
    );
  }
}
