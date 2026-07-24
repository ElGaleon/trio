import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/shared/sport_button.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';
import 'package:trio/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/settings/application/settings_provider.dart';
import 'package:trio/src/features/live_stats/presentation/stats_match_setup/stat_toggle_chip.dart';
import 'custom_stat_edit_dialog.dart';
import 'settings_section_title.dart';

class CustomStatsSettingsSection extends ConsumerWidget {
  const CustomStatsSettingsSection({super.key});

  static const _builtInItems = [
    (MatchStatType.pass, 'P', 'Passaggi'),
    (MatchStatType.huck, 'H', 'Huck'),
    (MatchStatType.catchDisc, 'C', 'Catch / possesso'),
    (MatchStatType.throwError, 'TE', 'Throw error'),
    (MatchStatType.catchError, 'RE', 'Receive error'),
    (MatchStatType.stallOut, 'S', 'Stall out'),
    (MatchStatType.block, 'B', 'Block'),
    (MatchStatType.pull, 'PU', 'Pull'),
    (MatchStatType.openError, 'A', 'Errore aperto'),
    (MatchStatType.deepError, 'BU', 'Errore buco'),
    (MatchStatType.resetError, 'R', 'Errore reset'),
    (MatchStatType.opponentError, 'TO', 'Throwaway avversario'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsFormProvider);
    final notifier = ref.read(settingsFormProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return GlassDecoration(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 14,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionTitle(
              icon: FIcons.settings,
              title: 'Statistiche personalizzate & Preferite',
              textTheme: textTheme,
            ),
            Text(
              'Aggiungi o modifica statistiche personalizzate ed imposta quali abilitare di default nelle nuove partite.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.sportMutedForeground(context),
                fontWeight: FontWeight.w700,
              ),
            ),

            // Subsection: List of Custom Stats
            Text(
              'Le tue statistiche personalizzate',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            if (state.customStats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nessuna statistica personalizzata creata. Clicca il pulsante sotto per aggiungerne una.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedForeground(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              Column(
                spacing: 12,
                children: [
                  for (final stat in state.customStats)
                    Row(
                      children: [
                        // Abbreviation badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.violet.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.violetLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stat.abbreviation,
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.sportForeground(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Label and weight details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.label,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.sportForeground(context),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Peso: ${stat.weight >= 0 ? '+' : ''}${stat.weight} · ${stat.isError ? 'Errore' : 'Azione positiva'}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.sportMutedForeground(
                                    context,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Favorite toggle star button
                        IconButton(
                          icon: Icon(
                            state.favoriteStatNames.contains(stat.id)
                                ? Icons.star
                                : Icons.star_border,
                            color: state.favoriteStatNames.contains(stat.id)
                                ? AppColors.violetLight
                                : AppColors.sportMutedText,
                          ),
                          onPressed: () => notifier.toggleFavoriteStat(stat.id),
                        ),
                        // Edit button
                        IconButton(
                          icon: Icon(
                            FIcons.pencil,
                            color: AppColors.sportForeground(context),
                            size: 18,
                          ),
                          onPressed: () async {
                            final result = await CustomStatEditDialog.show(
                              context,
                              initialStat: stat,
                            );
                            if (result != null) {
                              notifier.updateCustomStat(result);
                            }
                          },
                        ),
                        // Delete button
                        IconButton(
                          icon: Icon(
                            FIcons.trash,
                            color: AppColors.danger,
                            size: 18,
                          ),
                          onPressed: () => notifier.removeCustomStat(stat.id),
                        ),
                      ],
                    ),
                ],
              ),

            // Button to Add Custom Stat
            Align(
              alignment: Alignment.centerLeft,
              child: SportActionButton(
                label: 'Aggiungi Statistica',
                icon: FIcons.plus,
                onPressed: () async {
                  final result = await CustomStatEditDialog.show(context);
                  if (result != null) {
                    notifier.addCustomStat(result);
                  }
                },
              ),
            ),

            const Divider(color: AppColors.violet, height: 24),

            // Subsection: Favorite Default Built-in Stats
            Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiche preferite di default',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.sportForeground(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Seleziona quali statistiche saranno abilitate di default alla creazione di un nuovo match.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedForeground(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _builtInItems)
                  StatToggleChip(
                    code: item.$2,
                    label: item.$3,
                    selected: state.favoriteStatNames.contains(item.$1.name),
                    onTap: () => notifier.toggleFavoriteStat(item.$1.name),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
