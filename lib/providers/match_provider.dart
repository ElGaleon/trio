import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trio/model/scrimmage_match.dart';
import 'package:trio/providers/elo_providers.dart';

final matchDetailsProvider = Provider.family<ScrimmageMatch?, String>((
  ref,
  matchId,
) {
  final matches = ref.watch(matchesProvider);
  for (final m in matches) {
    if (m.id == matchId) return m;
  }
  return null;
});
