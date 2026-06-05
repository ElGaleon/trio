import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/match_detail_stats.dart';

class MatchDetailTabNotifier extends Notifier<MatchDetailTab> {
  final String matchId;
  MatchDetailTabNotifier(this.matchId);

  @override
  MatchDetailTab build() {
    return MatchDetailTab.facts;
  }

  void setTab(MatchDetailTab tab) {
    state = tab;
  }
}

final matchDetailTabProvider = NotifierProvider.autoDispose.family<MatchDetailTabNotifier, MatchDetailTab, String>(
  MatchDetailTabNotifier.new,
);

class MatchDetailSubTabNotifier extends Notifier<MatchDetailSubTab> {
  final String matchId;
  MatchDetailSubTabNotifier(this.matchId);

  @override
  MatchDetailSubTab build() {
    return MatchDetailSubTab.generali;
  }

  void setTab(MatchDetailSubTab tab) {
    state = tab;
  }
}

final matchDetailSubTabProvider = NotifierProvider.autoDispose.family<MatchDetailSubTabNotifier, MatchDetailSubTab, String>(
  MatchDetailSubTabNotifier.new,
);
