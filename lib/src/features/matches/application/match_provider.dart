import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skrim/src/features/matches/application/matches_providers.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';

final matchDetailsProvider = Provider.family<ScrimmageMatch?, String>((
  ref,
  id,
) {
  return ref
      .watch(matchesProvider)
      .where((match) => match.id == id)
      .firstOrNull;
});
