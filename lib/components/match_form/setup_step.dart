import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../app_constants.dart';

class SetupStep extends StatelessWidget {
  const SetupStep({
    super.key,
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
        spacing: 12,
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
            Padding(
              padding: const EdgeInsets.only(top: 2), // Adjust spacing
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: FTextFormField(
                      control: FTextFieldControl.managed(
                        controller: teamANameController,
                      ),
                      hint: 'Nome squadra A',
                    ),
                  ),
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
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2), // Adjust spacing
              child: FButton(
                variant: .outline,
                onPress: onRegenerateNames,
                prefix: const Icon(FIcons.dices, size: 16),
                child: const Text('Rigenera nomi'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
