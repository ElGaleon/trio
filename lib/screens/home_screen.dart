import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../providers/elo_providers.dart';
import 'matches_screen.dart';
import 'players_screen.dart';
import 'ranking_screen.dart';

enum HomeSection { ranking, matches, players }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.section});

  final HomeSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hiveChangesProvider);
    final index = section.index;
    final pages = const [RankingScreen(), MatchesScreen(), PlayersScreen()];
    return FScaffold(
      header: null,
      childPad: false,
      footer: FBottomNavigationBar(
        index: index,
        onChange: (index) => context.go(_locationForIndex(index)),
        children: const [
          FBottomNavigationBarItem(
            icon: Icon(FIcons.chartBar),
            label: Text('Ranking'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(Icons.scoreboard_outlined),
            label: Text('Matches'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.users),
            label: Text('Players'),
          ),
        ],
      ),
      child: pages[index],
    );
  }

  String _locationForIndex(int index) {
    return switch (HomeSection.values[index]) {
      HomeSection.ranking => AppRoutes.ranking,
      HomeSection.matches => AppRoutes.matches,
      HomeSection.players => AppRoutes.players,
    };
  }
}
