import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:skrim/src/shared/decorated_panel.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/settings/domain/custom_stat.dart';

class CustomStatEditDialog extends StatefulWidget {
  final CustomStat? initialStat;

  const CustomStatEditDialog({super.key, this.initialStat});

  static Future<CustomStat?> show(
    BuildContext context, {
    CustomStat? initialStat,
  }) {
    return showDialog<CustomStat>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.60),
      builder: (context) => CustomStatEditDialog(initialStat: initialStat),
    );
  }

  @override
  State<CustomStatEditDialog> createState() => _CustomStatEditDialogState();
}

class _CustomStatEditDialogState extends State<CustomStatEditDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _abbreviationController;
  late final TextEditingController _weightController;
  late bool _isError;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.initialStat?.label ?? '',
    );
    _abbreviationController = TextEditingController(
      text: widget.initialStat?.abbreviation ?? '',
    );
    _weightController = TextEditingController(
      text: widget.initialStat != null
          ? widget.initialStat!.weight.toString()
          : '1.0',
    );
    _isError = widget.initialStat?.isError ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _abbreviationController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onSave() {
    final label = _labelController.text.trim();
    final abbreviation = _abbreviationController.text.trim().toUpperCase();
    final weightVal = double.tryParse(_weightController.text.trim()) ?? 0.0;

    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome valido.')),
      );
      return;
    }

    if (abbreviation.isEmpty || abbreviation.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abbreviazione deve essere tra 1 e 3 caratteri.'),
        ),
      );
      return;
    }

    final result = CustomStat(
      id:
          widget.initialStat?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      abbreviation: abbreviation,
      isError: _isError,
      weight: weightVal,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: DecoratedPanel(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.initialStat == null
                        ? 'Nuova Statistica'
                        : 'Modifica Statistica',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  FTextFormField(
                    control: FTextFieldControl.managed(
                      controller: _labelController,
                    ),
                    hint: 'Nome (es. Hammer)',
                  ),
                  FTextFormField(
                    control: FTextFieldControl.managed(
                      controller: _abbreviationController,
                    ),
                    maxLength: 3,
                    hint: 'Abbreviazione (es. HM)',
                  ),
                  FTextFormField(
                    control: FTextFieldControl.managed(
                      controller: _weightController,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    hint: 'Peso ELO / Impatto (es. 1.5 o -2.0)',
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _isError = !_isError),
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Text(
                            'È un errore (turnover)',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.sportForeground(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          _isError ? FIcons.toggleRight : FIcons.toggleLeft,
                          color: _isError
                              ? AppColors.violetLight
                              : AppColors.sportMutedText,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    spacing: 12,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Annulla',
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.sportMutedForeground(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.violet,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Salva',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.sportForeground(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
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
