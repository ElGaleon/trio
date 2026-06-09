import 'package:trio/src/features/players/domain/player.dart';

class InjurySubstitutionDraft {
  const InjurySubstitutionDraft({
    required this.injured,
    required this.replacement,
  });

  final Player injured;
  final Player replacement;
}
