import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/features/organizations/presentation/organization_switcher.dart';
import 'package:trio/src/shared/responsive_layout.dart';
import 'package:trio/src/shared/sport_button.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';
import 'package:trio/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/settings/application/settings_provider.dart';
import 'package:trio/src/features/settings/application/theme_mode_provider.dart';
import 'package:trio/src/features/settings/domain/app_settings.dart';
import 'custom_stats_settings_section.dart';
import 'settings_section_title.dart';
import 'stat_weight_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _eloKFactorController;
  late final TextEditingController _initialRatingController;
  late final Map<MatchStatType, TextEditingController> _statWeightControllers;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(settingsFormProvider);
    _eloKFactorController = TextEditingController(
      text: initialState.eloKFactor,
    );
    _initialRatingController = TextEditingController(
      text: initialState.initialRating,
    );
    _statWeightControllers = {
      for (final type in AppSettings.defaultStatWeights.keys)
        type: TextEditingController(
          text: initialState.statWeights[type.name] ?? '0',
        ),
    };

    _eloKFactorController.addListener(() {
      ref
          .read(settingsFormProvider.notifier)
          .updateEloKFactor(_eloKFactorController.text);
    });
    _initialRatingController.addListener(() {
      ref
          .read(settingsFormProvider.notifier)
          .updateInitialRating(_initialRatingController.text);
    });
    for (final entry in _statWeightControllers.entries) {
      entry.value.addListener(() {
        ref
            .read(settingsFormProvider.notifier)
            .updateStatWeight(entry.key, entry.value.text);
      });
    }
  }

  @override
  void dispose() {
    _eloKFactorController.dispose();
    _initialRatingController.dispose();
    for (final controller in _statWeightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(settingsFormProvider.notifier);
    final themeModeIndex = ref.watch(themeModeIndexProvider);
    final textTheme = Theme.of(context).textTheme;
    final showMobileOrganizationSwitcher =
        MediaQuery.sizeOf(context).width < ResponsiveLayout.tablet;
    final saveButton = SportFloatingActionButton(
      label: 'Salva',
      icon: FIcons.save,
      onPressed: () => _save(context, notifier),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SportScreenShell(
        title: 'Settings',
        subtitle: 'Theme and ELO',
        headerActions: [if (kIsWeb) saveButton],
        child: Column(
          spacing: 12,
          children: [
            if (showMobileOrganizationSwitcher)
              GlassDecoration(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    spacing: 14,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsSectionTitle(
                        icon: Icons.business_outlined,
                        title: 'Organizzazione',
                        textTheme: textTheme,
                      ),
                      const OrganizationSwitcher(),
                    ],
                  ),
                ),
              ),
            GlassDecoration(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 14,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsSectionTitle(
                      icon: FIcons.palette,
                      title: 'Aspetto',
                      textTheme: textTheme,
                    ),
                    FSelect<int>(
                      key: ValueKey(themeModeIndex),
                      items: const {'Sistema': 0, 'Chiaro': 1, 'Scuro': 2},
                      hint: 'Tema',
                      control: FSelectControl.managed(
                        initial: themeModeIndex,
                        onChange: (value) {
                          if (value != null) {
                            notifier.updateThemeMode(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GlassDecoration(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 14,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsSectionTitle(
                      icon: FIcons.chartNoAxesCombined,
                      title: 'Algoritmo ELO',
                      textTheme: textTheme,
                    ),
                    FTextFormField(
                      control: FTextFieldControl.managed(
                        controller: _eloKFactorController,
                      ),
                      keyboardType: TextInputType.number,
                      hint: 'Coefficiente ELO · default 32',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2), // Adjust spacing
                      child: FTextFormField(
                        control: FTextFieldControl.managed(
                          controller: _initialRatingController,
                        ),
                        keyboardType: TextInputType.number,
                        hint: 'Punteggio di partenza · default 1000',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GlassDecoration(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 14,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsSectionTitle(
                      icon: FIcons.activity,
                      title: 'Pesi statistiche',
                      textTheme: textTheme,
                    ),
                    Text(
                      'I nuovi valori valgono solo per le statistiche registrate dopo il salvataggio.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.sportMutedForeground(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    for (final entry in _statWeightControllers.entries)
                      StatWeightField(type: entry.key, controller: entry.value),
                  ],
                ),
              ),
            ),
            const CustomStatsSettingsSection(),
            if (!kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: saveButton,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    SettingsFormNotifier notifier,
  ) async {
    final success = await notifier.save();
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Impostazioni salvate.')));
      if (context.canPop()) context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci valori numerici validi.')),
      );
    }
  }
}
