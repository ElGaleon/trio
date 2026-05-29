import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trio/screens/matches_screen.dart';
import 'package:trio/screens/players_screen.dart';
import 'package:trio/screens/ranking_screen.dart';

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  final _headers = [
    const FHeader(title: Text('Ranking')),
    const FHeader(title: Text('Matches')),
    const FHeader(title: Text('Players')),
  ];

  final _contents = [RankingScreen(), MatchesScreen(), PlayersScreen()];

  int _index = 1;

  @override
  Widget build(BuildContext _) => SizedBox(
    height: 500,
    child: FScaffold(
      header: _headers[_index],
      footer: FBottomNavigationBar(
        index: _index,
        onChange: (index) => setState(() => _index = index),
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
            icon: Icon(FIcons.personStanding),
            label: Text('Players'),
          ),
        ],
      ),
      child: _contents[_index],
    ),
  );
}
