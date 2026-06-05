import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trio/model/scrimmage_match.dart';
import 'package:trio/providers/elo_providers.dart';

final matchDetailsProvider = Provider.family<ScrimmageMatch?, String>((
  ref,
  matchId,
) {
  final repository = ref.watch(eloRepositoryProvider);
  return repository.getMatch(matchId);
});
