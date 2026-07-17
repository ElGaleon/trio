import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/features/players/application/player_providers.dart';
import 'package:trio/src/shared/responsive_layout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hiveChangesProvider);
    final wide = ResponsiveLayout.isWide(context);

    return FScaffold(
      header: null,
      childPad: false,
      sidebar: wide ? _Sidebar(navigationShell: navigationShell) : null,
      footer: wide
          ? null
          : FBottomNavigationBar(
              index: navigationShell.currentIndex,
              onChange: _goBranch,
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

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return FSidebar(
      header: const Padding(
        padding: EdgeInsets.fromLTRB(24, 18, 24, 8),
        child: Text('TRIO', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      children: [
        FSidebarGroup(
          label: const Text('Navigazione'),
          children: [
            _item(0, FIcons.chartBar, 'Ranking'),
            _item(1, Icons.scoreboard_outlined, 'Matches'),
            _item(2, FIcons.users, 'Players'),
            _item(3, FIcons.activity, 'Stats'),
            _item(4, FIcons.settings, 'Settings'),
          ],
        ),
      ],
    );
  }

  FSidebarItem _item(int index, IconData icon, String label) {
    return FSidebarItem(
      icon: Icon(icon),
      label: Text(label),
      selected: navigationShell.currentIndex == index,
      onPress: () {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
    );
  }
}
