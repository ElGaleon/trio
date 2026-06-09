import 'package:trio/src/features/players/domain/player.dart';

class PullDraft {
  const PullDraft({
    required this.player,
    required this.durationSeconds,
    required this.inBounds,
  });

  final Player player;
  final int durationSeconds;
  final bool inBounds;
}
