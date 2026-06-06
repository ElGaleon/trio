import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../providers/elo_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hiveChangesProvider);

    return FScaffold(
      header: null,
      childPad: false,
      footer: FBottomNavigationBar(
        index: navigationShell.currentIndex,
        onChange: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
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
          FBottomNavigationBarItem(
            icon: Icon(FIcons.activity),
            label: Text('Stats'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.settings),
            label: Text('Settings'),
          ),
        ],
      ),
      child: navigationShell,
    );
  }
}
