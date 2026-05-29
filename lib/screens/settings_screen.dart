import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../app_constants.dart';
import '../models/app_settings.dart';
import '../providers/elo_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late int _themeModeIndex;
  late final TextEditingController _eloKFactorController;
  late final TextEditingController _initialRatingController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _themeModeIndex = settings.themeModeIndex;
    _eloKFactorController = TextEditingController(
      text: settings.eloKFactor.round().toString(),
    );
    _initialRatingController = TextEditingController(
      text: settings.initialRating.round().toString(),
    );
  }

  @override
  void dispose() {
    _eloKFactorController.dispose();
    _initialRatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aspetto', style: textTheme.titleMedium),
                  const SizedBox(height: 14),
                  FSelect<int>(
                    items: const {'Sistema': 0, 'Chiaro': 1, 'Scuro': 2},
                    hint: 'Tema',
                    control: FSelectControl.managed(
                      initial: _themeModeIndex,
                      onChange: (value) {
                        if (value != null) {
                          setState(() => _themeModeIndex = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Algoritmo ELO', style: textTheme.titleMedium),
                  const SizedBox(height: 14),
                  FTextFormField(
                    control: FTextFieldControl.managed(
                      controller: _eloKFactorController,
                    ),
                    keyboardType: TextInputType.number,
                    hint: 'Coefficiente ELO · default 32',
                  ),
                  const SizedBox(height: 12),
                  FTextFormField(
                    control: FTextFieldControl.managed(
                      controller: _initialRatingController,
                    ),
                    keyboardType: TextInputType.number,
                    hint: 'Punteggio di partenza · default 1000',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FButton(
            onPress: _save,
            prefix: const Icon(Icons.save_outlined, size: 16),
            child: const Text('Salva impostazioni'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final eloKFactor = double.tryParse(_eloKFactorController.text.trim());
    final initialRating = double.tryParse(_initialRatingController.text.trim());
    if (eloKFactor == null ||
        initialRating == null ||
        eloKFactor <= 0 ||
        initialRating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci valori numerici maggiori di zero.'),
        ),
      );
      return;
    }

    final settingsBox = ref.read(settingsBoxProvider);
    await settingsBox.put(
      AppConstants.settingsKey,
      AppSettings(
        themeModeIndex: _themeModeIndex,
        eloKFactor: eloKFactor,
        initialRating: initialRating,
      ),
    );
    ref
      ..invalidate(appSettingsProvider)
      ..invalidate(eloRepositoryProvider);
    await ref.read(eloRepositoryProvider).recalculateRatings();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Impostazioni salvate.')));
  }
}
