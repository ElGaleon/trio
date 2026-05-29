import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../app_constants.dart';
import '../models/player.dart';
import '../models/scrimmage_match.dart';
import '../providers/elo_providers.dart';
import '../repositories/elo_repository.dart';
import '../widgets/animated_score_stepper.dart';

class MatchFormScreen extends ConsumerStatefulWidget {
  const MatchFormScreen({super.key, this.match});

  final ScrimmageMatch? match;

  @override
  ConsumerState<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends ConsumerState<MatchFormScreen> {
  late final TextEditingController _teamANameController;
  late final TextEditingController _teamBNameController;
  late final Set<String> _teamAIds;
  late final Set<String> _teamBIds;
  late int _scoreA;
  late int _scoreB;
  late int _teamSize;
  late bool _offenseVsDefense;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    final names = _randomTeamNames();
    _teamANameController = TextEditingController(
      text: widget.match?.teamAName ?? names.$1,
    );
    _teamBNameController = TextEditingController(
      text: widget.match?.teamBName ?? names.$2,
    );
    _teamAIds = <String>{...?widget.match?.teamAIds};
    _teamBIds = <String>{...?widget.match?.teamBIds};
    _scoreA = widget.match?.scoreA ?? 0;
    _scoreB = widget.match?.scoreB ?? 0;
    _teamSize = widget.match?.teamSize ?? AppConstants.defaultTeamSize;
    _offenseVsDefense = widget.match?.offenseVsDefense ?? false;
  }

  @override
  void dispose() {
    _teamANameController.dispose();
    _teamBNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(eloRepositoryProvider);
    final players = repository.rankedPlayers;
    final recentTeams = ref.watch(recentMatchTeamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.match == null ? 'Nuova partita' : 'Modifica partita',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StepHeader(step: _step),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _buildStep(players, recentTeams),
              ),
            ),
            const SizedBox(height: 88),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FButton(
                  variant: .outline,
                  onPress: _step == 0
                      ? () => Navigator.pop(context)
                      : () => setState(() => _step -= 1),
                  child: Text(_step == 0 ? 'Annulla' : 'Indietro'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FButton(
                  onPress: _canContinue ? () => _continue(repository) : null,
                  child: Text(_step == 3 ? 'Salva' : 'Avanti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(List<Player> players, List<RecentMatchTeam> recentTeams) {
    return switch (_step) {
      0 => _SetupStep(
        teamSize: _teamSize,
        offenseVsDefense: _offenseVsDefense,
        teamANameController: _teamANameController,
        teamBNameController: _teamBNameController,
        onTeamSizeChanged: (value) => setState(() => _teamSize = value),
        onRegenerateNames: _regenerateTeamNames,
        onModeChanged: (value) => setState(() {
          _offenseVsDefense = value;
          if (value) {
            _teamANameController.text = 'Attacco';
            _teamBNameController.text = 'Difesa';
            _teamAIds
              ..clear()
              ..addAll(
                players
                    .where(
                      (player) =>
                          player.linePreference == PlayerLinePreference.offense,
                    )
                    .map((player) => player.id),
              );
            _teamBIds
              ..clear()
              ..addAll(
                players
                    .where(
                      (player) =>
                          player.linePreference == PlayerLinePreference.defense,
                    )
                    .map((player) => player.id),
              );
          } else {
            _regenerateTeamNames();
          }
        }),
      ),
      1 => _PresenceStep(
        title: _teamALabel,
        description: 'Segna tutti i presenti della prima squadra.',
        count: _teamAIds.length,
        minimum: _teamSize,
        suggestedLine: _offenseVsDefense ? PlayerLinePreference.offense : null,
        players: players,
        recentTeams: recentTeams,
        selectedIds: _teamAIds,
        disabledIds: _teamBIds,
        onChanged: _toggleTeamA,
        onApplyRecentTeam: (team) => _applyRecentTeam(team, toTeamA: true),
      ),
      2 => _PresenceStep(
        title: _teamBLabel,
        description: 'Segna tutti i presenti della seconda squadra.',
        count: _teamBIds.length,
        minimum: _teamSize,
        suggestedLine: _offenseVsDefense ? PlayerLinePreference.defense : null,
        players: players,
        recentTeams: recentTeams,
        selectedIds: _teamBIds,
        disabledIds: _teamAIds,
        onChanged: _toggleTeamB,
        onApplyRecentTeam: (team) => _applyRecentTeam(team, toTeamA: false),
      ),
      _ => _ScoreStep(
        scoreA: _scoreA,
        scoreB: _scoreB,
        onScoreAChanged: (value) => setState(() => _scoreA = value),
        onScoreBChanged: (value) => setState(() => _scoreB = value),
        teamSize: _teamSize,
        teamALabel: _teamALabel,
        teamBLabel: _teamBLabel,
        teamACount: _teamAIds.length,
        teamBCount: _teamBIds.length,
      ),
    };
  }

  bool get _canContinue {
    return switch (_step) {
      0 => true,
      1 => _teamAIds.length >= _teamSize,
      2 => _teamBIds.length >= _teamSize,
      _ => _teamAIds.length >= _teamSize && _teamBIds.length >= _teamSize,
    };
  }

  void _continue(EloRepository repository) {
    if (_step < 3) {
      setState(() => _step += 1);
      return;
    }
    _save(repository);
  }

  void _toggleTeamA(String id) {
    setState(() {
      _teamAIds.contains(id) ? _teamAIds.remove(id) : _teamAIds.add(id);
    });
  }

  void _toggleTeamB(String id) {
    setState(() {
      _teamBIds.contains(id) ? _teamBIds.remove(id) : _teamBIds.add(id);
    });
  }

  void _applyRecentTeam(RecentMatchTeam team, {required bool toTeamA}) {
    setState(() {
      final ids = team.playerIds.toSet();
      if (toTeamA) {
        _teamAIds
          ..clear()
          ..addAll(ids);
        _teamBIds.removeAll(ids);
        _teamANameController.text = team.name;
      } else {
        _teamBIds
          ..clear()
          ..addAll(ids);
        _teamAIds.removeAll(ids);
        _teamBNameController.text = team.name;
      }
    });
  }

  Future<void> _save(EloRepository repository) async {
    final savedMatch = ScrimmageMatch(
      id: widget.match?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: widget.match?.createdAt ?? DateTime.now(),
      teamAIds: _teamAIds.toList(),
      teamBIds: _teamBIds.toList(),
      scoreA: _scoreA,
      scoreB: _scoreB,
      teamSize: _teamSize,
      offenseVsDefense: _offenseVsDefense,
      teamAName: _teamALabel,
      teamBName: _teamBLabel,
    );
    await repository.upsertMatch(savedMatch);
    if (!mounted) return;
    Navigator.pop(context);
  }

  String get _teamALabel {
    final name = _teamANameController.text.trim();
    return name.isEmpty ? (_offenseVsDefense ? 'Attacco' : 'Squadra A') : name;
  }

  String get _teamBLabel {
    final name = _teamBNameController.text.trim();
    return name.isEmpty ? (_offenseVsDefense ? 'Difesa' : 'Squadra B') : name;
  }

  void _regenerateTeamNames() {
    final names = _randomTeamNames();
    _teamANameController.text = names.$1;
    _teamBNameController.text = names.$2;
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final labels = ['Setup', 'A', 'B', 'Score'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index == step;
        final completed = index < step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            child: FBadge(
              variant: active || completed ? .primary : .outline,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(completed ? FIcons.check : FIcons.circle, size: 12),
                  const SizedBox(width: 5),
                  Flexible(child: Text(labels[index])),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.teamSize,
    required this.offenseVsDefense,
    required this.teamANameController,
    required this.teamBNameController,
    required this.onTeamSizeChanged,
    required this.onModeChanged,
    required this.onRegenerateNames,
  });

  final int teamSize;
  final bool offenseVsDefense;
  final TextEditingController teamANameController;
  final TextEditingController teamBNameController;
  final ValueChanged<int> onTeamSizeChanged;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onRegenerateNames;

  @override
  Widget build(BuildContext context) {
    return FCard(
      title: const Text('Impostazioni partita'),
      subtitle: const Text('Scegli formato e tipo di confronto.'),
      child: Column(
        children: [
          FSelect<int>(
            items: {
              for (
                var size = AppConstants.minTeamSize;
                size <= AppConstants.maxTeamSize;
                size++
              )
                '${size}vs$size': size,
            },
            hint: 'Formato',
            control: FSelectControl.managed(
              initial: teamSize,
              onChange: (value) {
                if (value != null) onTeamSizeChanged(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          FTileGroup(
            children: [
              FTile(
                prefix: const Icon(FIcons.users),
                title: const Text('Squadre libere'),
                subtitle: const Text('Selezione manuale dei presenti.'),
                suffix: offenseVsDefense
                    ? null
                    : const Icon(FIcons.check, size: 18),
                onPress: () => onModeChanged(false),
              ),
              FTile(
                prefix: const Icon(FIcons.shield),
                title: const Text('Attacco vs difesa'),
                subtitle: const Text('Precompila le linee attacco e difesa.'),
                suffix: offenseVsDefense
                    ? const Icon(FIcons.check, size: 18)
                    : null,
                onPress: () => onModeChanged(true),
              ),
            ],
          ),
          if (!offenseVsDefense) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FTextFormField(
                    control: FTextFieldControl.managed(
                      controller: teamANameController,
                    ),
                    hint: 'Nome squadra A',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FTextFormField(
                    control: FTextFieldControl.managed(
                      controller: teamBNameController,
                    ),
                    hint: 'Nome squadra B',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FButton(
              variant: .outline,
              onPress: onRegenerateNames,
              prefix: const Icon(FIcons.dices, size: 16),
              child: const Text('Rigenera nomi'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresenceStep extends StatelessWidget {
  const _PresenceStep({
    required this.title,
    required this.description,
    required this.count,
    required this.minimum,
    required this.players,
    required this.recentTeams,
    required this.selectedIds,
    required this.disabledIds,
    required this.onChanged,
    required this.onApplyRecentTeam,
    this.suggestedLine,
  });

  final String title;
  final String description;
  final int count;
  final int minimum;
  final List<Player> players;
  final List<RecentMatchTeam> recentTeams;
  final Set<String> selectedIds;
  final Set<String> disabledIds;
  final ValueChanged<String> onChanged;
  final ValueChanged<RecentMatchTeam> onApplyRecentTeam;
  final PlayerLinePreference? suggestedLine;

  @override
  Widget build(BuildContext context) {
    final visiblePlayers = players.where((player) {
      if (suggestedLine == null) return true;
      if (disabledIds.contains(player.id)) return false;
      return player.linePreference == suggestedLine;
    }).toList();

    final sortedPlayers = visiblePlayers
      ..sort((a, b) {
        final aSuggested = a.linePreference == suggestedLine ? 0 : 1;
        final bSuggested = b.linePreference == suggestedLine ? 0 : 1;
        final byLine = aSuggested.compareTo(bSuggested);
        if (byLine != 0) return byLine;
        return a.name.compareTo(b.name);
      });

    return FCard(
      title: Row(
        children: [
          Expanded(child: Text(title)),
          FBadge(
            variant: count >= minimum ? .primary : .outline,
            child: Text('$count/$minimum min'),
          ),
        ],
      ),
      subtitle: Text(description),
      child: Column(
        children: [
          if (recentTeams.isNotEmpty) ...[
            _RecentTeamsPicker(
              recentTeams: recentTeams,
              selectedIds: selectedIds,
              onApplyRecentTeam: onApplyRecentTeam,
            ),
            const SizedBox(height: 12),
          ],
          FTileGroup(
            children: [
              ...sortedPlayers.map((player) {
                final selected = selectedIds.contains(player.id);
                final disabled = disabledIds.contains(player.id);
                return FTile(
                  enabled: !disabled,
                  selected: selected,
                  prefix: Icon(_lineIcon(player.linePreference)),
                  title: Text(player.name),
                  subtitle: Text(
                    '${player.role.label} · ${player.linePreference.label}',
                  ),
                  suffix: selected
                      ? const Icon(FIcons.check, size: 18)
                      : disabled
                      ? const Icon(FIcons.x, size: 18)
                      : null,
                  onPress: disabled ? null : () => onChanged(player.id),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  IconData _lineIcon(PlayerLinePreference linePreference) {
    return switch (linePreference) {
      PlayerLinePreference.offense => FIcons.arrowUpRight,
      PlayerLinePreference.defense => FIcons.shield,
    };
  }
}

class _RecentTeamsPicker extends StatelessWidget {
  const _RecentTeamsPicker({
    required this.recentTeams,
    required this.selectedIds,
    required this.onApplyRecentTeam,
  });

  final List<RecentMatchTeam> recentTeams;
  final Set<String> selectedIds;
  final ValueChanged<RecentMatchTeam> onApplyRecentTeam;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(FIcons.history, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Squadre di oggi',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FTileGroup(
          children: [
            ...recentTeams.map((team) {
              final selected = _hasSameMembers(selectedIds, team.playerIds);
              return FTile(
                selected: selected,
                prefix: const Icon(FIcons.zap, size: 18),
                title: Text(team.name),
                subtitle: Text(team.playerNames.join(', ')),
                details: FBadge(
                  variant: selected ? .primary : .secondary,
                  child: Text('${team.playerIds.length}'),
                ),
                suffix: selected ? const Icon(FIcons.check, size: 18) : null,
                onPress: () => onApplyRecentTeam(team),
              );
            }),
          ],
        ),
      ],
    );
  }
}

bool _hasSameMembers(Set<String> selectedIds, List<String> teamIds) {
  if (selectedIds.length != teamIds.length) return false;
  return teamIds.every(selectedIds.contains);
}

class _ScoreStep extends StatelessWidget {
  const _ScoreStep({
    required this.scoreA,
    required this.scoreB,
    required this.onScoreAChanged,
    required this.onScoreBChanged,
    required this.teamSize,
    required this.teamALabel,
    required this.teamBLabel,
    required this.teamACount,
    required this.teamBCount,
  });

  final int scoreA;
  final int scoreB;
  final ValueChanged<int> onScoreAChanged;
  final ValueChanged<int> onScoreBChanged;
  final int teamSize;
  final String teamALabel;
  final String teamBLabel;
  final int teamACount;
  final int teamBCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FCard(
          title: const Text('Riepilogo'),
          child: Column(
            children: [
              _SummaryRow(label: 'Formato', value: '${teamSize}vs$teamSize'),
              _SummaryRow(label: teamALabel, value: '$teamACount presenti'),
              _SummaryRow(label: teamBLabel, value: '$teamBCount presenti'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedScoreStepper(
                label: teamALabel,
                value: scoreA,
                onChanged: onScoreAChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedScoreStepper(
                label: teamBLabel,
                value: scoreB,
                onChanged: onScoreBChanged,
              ),
            ),
          ],
        ),
        if (scoreA == scoreB) ...[
          const SizedBox(height: 10),
          FBadge(variant: .secondary, child: const Text('Pareggio')),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

(String, String) _randomTeamNames() {
  const names = [
    'Vento',
    'Tuono',
    'Lampo',
    'Onde',
    'Fuoco',
    'Nebbia',
    'Falchi',
    'Comete',
    'Spirali',
    'Scie',
    'Sole',
    'Lune',
  ];
  final seed = DateTime.now().microsecondsSinceEpoch;
  final first = seed % names.length;
  final second = (first + 3 + (seed ~/ 7) % (names.length - 1)) % names.length;
  return (
    names[first],
    names[second == first ? (second + 1) % names.length : second],
  );
}
