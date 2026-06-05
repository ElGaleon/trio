class SettingsFormState {
  final int themeModeIndex;
  final String eloKFactor;
  final String initialRating;
  final Map<String, String> statWeights;

  SettingsFormState({
    required this.themeModeIndex,
    required this.eloKFactor,
    required this.initialRating,
    required this.statWeights,
  });

  SettingsFormState copyWith({
    int? themeModeIndex,
    String? eloKFactor,
    String? initialRating,
    Map<String, String>? statWeights,
  }) {
    return SettingsFormState(
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      eloKFactor: eloKFactor ?? this.eloKFactor,
      initialRating: initialRating ?? this.initialRating,
      statWeights: statWeights ?? this.statWeights,
    );
  }
}
