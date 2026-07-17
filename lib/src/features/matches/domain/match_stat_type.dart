enum MatchStatType {
  pass,
  huck,
  assist,
  goal,
  defense,
  catchDisc,
  stallOut,
  block,
  openError,
  deepError,
  resetError,
  throwError,
  catchError,
  opponentGoal,
  opponentError,
  timeout,
  injury,
  halfTime,
  timeoutEnd,
  halfTimeEnd,
  matchEnd,
  lineup,
  pull,
  custom;

  String get label {
    return switch (this) {
      MatchStatType.pass => 'Passaggio',
      MatchStatType.huck => 'Huck',
      MatchStatType.assist => 'Assist',
      MatchStatType.goal => 'Meta',
      MatchStatType.defense => 'Difesa',
      MatchStatType.catchDisc => 'Catch',
      MatchStatType.stallOut => 'Stall out',
      MatchStatType.block => 'Block',
      MatchStatType.openError => 'Aperto',
      MatchStatType.deepError => 'Buco',
      MatchStatType.resetError => 'Reset',
      MatchStatType.throwError => 'Errore lancio',
      MatchStatType.catchError => 'Errore presa',
      MatchStatType.opponentGoal => 'Meta avversaria',
      MatchStatType.opponentError => 'Errore avversario',
      MatchStatType.timeout => 'Timeout',
      MatchStatType.injury => 'Infortunio',
      MatchStatType.halfTime => 'Half time',
      MatchStatType.timeoutEnd => 'Fine timeout',
      MatchStatType.halfTimeEnd => 'Fine half time',
      MatchStatType.matchEnd => 'Fine partita',
      MatchStatType.lineup => 'Linea',
      MatchStatType.pull => 'Pull',
      MatchStatType.custom => 'Custom',
    };
  }

  static List<MatchStatType> get defaultEnabled {
    return const [
      MatchStatType.pass,
      MatchStatType.huck,
      MatchStatType.catchDisc,
      MatchStatType.stallOut,
      MatchStatType.block,
      MatchStatType.pull,
      MatchStatType.openError,
      MatchStatType.deepError,
      MatchStatType.resetError,
      MatchStatType.throwError,
      MatchStatType.catchError,
      MatchStatType.opponentError,
    ];
  }

  bool get isError {
    return this == MatchStatType.throwError ||
        this == MatchStatType.catchError ||
        this == MatchStatType.stallOut ||
        this == MatchStatType.openError ||
        this == MatchStatType.deepError ||
        this == MatchStatType.resetError;
  }
}
