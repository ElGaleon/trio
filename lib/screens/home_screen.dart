import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../app_constants.dart';
import '../providers/elo_providers.dart';
import 'matches_screen.dart';
import 'players_screen.dart';
import 'ranking_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(hiveChangesProvider);
    final pages = const [RankingScreen(), MatchesScreen(), PlayersScreen()];
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FButton.icon(
              variant: .ghost,
              size: .sm,
              onPress: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: const Icon(Icons.settings_outlined, size: 18),
            ),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  _NavButton(
                    label: 'Ranking',
                    icon: Icons.emoji_events_outlined,
                    selected: _index == 0,
                    onPressed: () => setState(() => _index = 0),
                  ),
                  _NavButton(
                    label: 'Partite',
                    icon: Icons.calendar_month_outlined,
                    selected: _index == 1,
                    onPressed: () => setState(() => _index = 1),
                  ),
                  _NavButton(
                    label: 'Giocatori',
                    icon: Icons.groups_outlined,
                    selected: _index == 2,
                    onPressed: () => setState(() => _index = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FButton(
        variant: selected ? .secondary : .ghost,
        onPress: onPressed,
        prefix: Icon(icon, size: 16),
        child: Text(label),
      ),
    );
  }
}
