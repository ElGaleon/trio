import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/players/application/player_providers.dart';

final matchDetailsProvider =
    Provider.family<ScrimmageMatch?, String>((ref, id) {
  ref.watch(hiveChangesProvider);
  return ref.watch(eloRepositoryProvider).getMatch(id);
});
