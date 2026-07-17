import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/shared/decorated_panel.dart';
import 'package:trio/src/shared/sport_button.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'injury_substitution_draft.dart';
import 'substitution_section.dart';

class InjurySubstitutionSheet {
  const InjurySubstitutionSheet._();

  static Future<InjurySubstitutionDraft?> show(
    BuildContext context, {
    required List<Player> currentPlayers,
    required List<Player> allPlayers,
  }) {
    Player? injured = currentPlayers.isEmpty ? null : currentPlayers.first;
    Player? replacement;

    List<Player> candidatesFor(Player? injuredPlayer) {
      final currentIds = currentPlayers.map((player) => player.id).toSet();
      final candidates = allPlayers
          .where((player) => !currentIds.contains(player.id))
          .toList();
      candidates.sort((a, b) {
        if (injuredPlayer != null) {
          final role = (a.role == injuredPlayer.role ? 0 : 1).compareTo(
            b.role == injuredPlayer.role ? 0 : 1,
          );
          if (role != 0) return role;
          final line =
              (a.linePreference == injuredPlayer.linePreference ? 0 : 1)
                  .compareTo(
                    b.linePreference == injuredPlayer.linePreference ? 0 : 1,
                  );
          if (line != 0) return line;
        }
        return a.name.compareTo(b.name);
      });
      return candidates;
    }

    return showModalBottomSheet<InjurySubstitutionDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final candidates = candidatesFor(injured);
            if (replacement != null &&
                !candidates.any((player) => player.id == replacement!.id)) {
              replacement = null;
            }
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: DecoratedPanel(
                  radius: 28,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      spacing: 12,
                      children: [
                        Text(
                          'Cambio per infortunio',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        SubstitutionSection(
                          title: 'Chi esce',
                          players: currentPlayers,
                          selectedId: injured?.id,
                          onSelect: (player) {
                            setSheetState(() {
                              injured = player;
                              replacement = null;
                            });
                          },
                        ),
                        Expanded(
                          child: SubstitutionSection(
                            title: 'Chi entra',
                            players: candidates,
                            selectedId: replacement?.id,
                            highlightRole: injured?.role,
                            onSelect: (player) {
                              setSheetState(() => replacement = player);
                            },
                          ),
                        ),
                        SportFloatingActionButton(
                          label: injured != null && replacement != null
                              ? 'Conferma cambio'
                              : 'Seleziona cambio',
                          icon: FIcons.plus,
                          onPressed: injured != null && replacement != null
                              ? () => Navigator.pop(
                                  context,
                                  InjurySubstitutionDraft(
                                    injured: injured!,
                                    replacement: replacement!,
                                  ),
                                )
                              : () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
