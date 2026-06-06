import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../components/settings/settings_section_title.dart';
import '../components/shared/sport_avatar_pill.dart';
import '../components/shared/sport_button.dart';
import '../components/shared/sport_screen_shell.dart';
import '../model/app_settings.dart';
import '../model/scrimmage_match.dart';
import '../providers/settings_provider.dart';

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
    final state = ref.watch(settingsFormProvider);
    final notifier = ref.read(settingsFormProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SportScreenShell(
        title: 'Settings',
        subtitle: 'Theme and ELO',
        child: Column(
          spacing: 12,
          children: [
            DecoratedBox(
              decoration: sportGlassDecoration(),
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
                      items: const {'Sistema': 0, 'Chiaro': 1, 'Scuro': 2},
                      hint: 'Tema',
                      control: FSelectControl.managed(
                        initial: state.themeModeIndex,
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
            DecoratedBox(
              decoration: sportGlassDecoration(),
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
            DecoratedBox(
              decoration: sportGlassDecoration(),
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
                        color: sportMutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    for (final entry in _statWeightControllers.entries)
                      _StatWeightField(
                        type: entry.key,
                        controller: entry.value,
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SportFloatingActionButton(
                label: 'Salva',
                icon: FIcons.save,
                onPressed: () => _save(context, notifier),
              ),
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

class _StatWeightField extends StatelessWidget {
  const _StatWeightField({required this.type, required this.controller});

  final MatchStatType type;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Text(
            type.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          width: 96,
          child: FTextFormField(
            control: FTextFieldControl.managed(controller: controller),
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            hint: '0',
          ),
        ),
      ],
    );
  }
}
