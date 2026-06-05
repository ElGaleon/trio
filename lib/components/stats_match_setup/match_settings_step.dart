import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../model/scrimmage_match.dart';
import '../shared/sport_avatar_pill.dart';
import 'setting_stepper.dart';
import 'stats_settings_selector.dart';
import 'toggle_setting.dart';

class MatchSettingsStep extends StatelessWidget {
  const MatchSettingsStep({
    super.key,
    required this.teamController,
    required this.opponentController,
    required this.tournamentController,
    required this.locationController,
    required this.division,
    required this.matchType,
    required this.teamSize,
    required this.windKmh,
    required this.pointsLimit,
    required this.durationMinutes,
    required this.hasHalfTime,
    required this.halfTimeSeconds,
    required this.hasTimeouts,
    required this.timeoutsPerTeamPerHalf,
    required this.timeoutSeconds,
    required this.enabledStatTypes,
    required this.onDivisionChanged,
    required this.onMatchTypeChanged,
    required this.onTeamSizeChanged,
    required this.onWindChanged,
    required this.onPointsChanged,
    required this.onDurationChanged,
    required this.onHalfTimeToggle,
    required this.onHalfTimeSecondsChanged,
    required this.onTimeoutToggle,
    required this.onTimeoutsPerHalfChanged,
    required this.onTimeoutSecondsChanged,
    required this.onToggleStat,
  });

  final TextEditingController teamController;
  final TextEditingController opponentController;
  final TextEditingController tournamentController;
  final TextEditingController locationController;
  final String division;
  final String matchType;
  final int teamSize;
  final int windKmh;
  final int pointsLimit;
  final int durationMinutes;
  final bool hasHalfTime;
  final int halfTimeSeconds;
  final bool hasTimeouts;
  final int timeoutsPerTeamPerHalf;
  final int timeoutSeconds;
  final Set<MatchStatType> enabledStatTypes;
  final ValueChanged<String> onDivisionChanged;
  final ValueChanged<String> onMatchTypeChanged;
  final ValueChanged<int> onTeamSizeChanged;
  final ValueChanged<int> onWindChanged;
  final ValueChanged<int> onPointsChanged;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onHalfTimeToggle;
  final ValueChanged<int> onHalfTimeSecondsChanged;
  final VoidCallback onTimeoutToggle;
  final ValueChanged<int> onTimeoutsPerHalfChanged;
  final ValueChanged<int> onTimeoutSecondsChanged;
  final ValueChanged<MatchStatType> onToggleStat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: sportGlassDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          children: [
            FTextFormField(
              control: FTextFieldControl.managed(controller: teamController),
              hint: 'La tua squadra',
            ),
            FSelect<String>(
              items: const {'Mixed': 'Mixed', 'Open': 'Open', 'Women': 'Women'},
              hint: 'Division',
              control: FSelectControl.managed(
                initial: division,
                onChange: (value) {
                  if (value != null) onDivisionChanged(value);
                },
              ),
            ),
            FTextFormField(
              control: FTextFieldControl.managed(controller: opponentController),
              hint: 'Squadra avversaria',
            ),
            FTextFormField(
              control: FTextFieldControl.managed(
                controller: tournamentController,
              ),
              hint: 'Torneo',
            ),
            FSelect<String>(
              items: const {
                'Classic': 'Classic',
                'Finale': 'Finale',
                'Allenamento': 'Allenamento',
              },
              hint: 'Tipo partita',
              control: FSelectControl.managed(
                initial: matchType,
                onChange: (value) {
                  if (value != null) onMatchTypeChanged(value);
                },
              ),
            ),
            FSelect<int>(
              items: {for (var i = 3; i <= 7; i++) '${i}vs$i': i},
              hint: 'Formato',
              control: FSelectControl.managed(
                initial: teamSize,
                onChange: (value) {
                  if (value != null) onTeamSizeChanged(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4), // Small extra spacing for the steppers group
              child: Column(
                children: [
                  SettingStepper(
                    label: 'Vento',
                    value: windKmh,
                    suffix: 'km/h',
                    min: 0,
                    max: 60,
                    step: 1,
                    onChanged: onWindChanged,
                  ),
                  SettingStepper(
                    label: 'Punti',
                    value: pointsLimit,
                    suffix: '',
                    min: 1,
                    max: 21,
                    step: 1,
                    onChanged: onPointsChanged,
                  ),
                  SettingStepper(
                    label: 'Durata',
                    value: durationMinutes,
                    suffix: 'min',
                    min: 10,
                    max: 120,
                    step: 5,
                    onChanged: onDurationChanged,
                  ),
                ],
              ),
            ),
            FTextFormField(
              control: FTextFieldControl.managed(controller: locationController),
              hint: 'Location',
            ),
            ToggleSetting(
              title: 'Half time',
              enabled: hasHalfTime,
              detail: '${halfTimeSeconds}s',
              onToggle: onHalfTimeToggle,
              child: hasHalfTime
                  ? SettingStepper(
                      label: 'Durata',
                      value: halfTimeSeconds,
                      suffix: 'sec',
                      min: 60,
                      max: 900,
                      step: 30,
                      onChanged: onHalfTimeSecondsChanged,
                    )
                  : null,
            ),
            ToggleSetting(
              title: 'Time out',
              enabled: hasTimeouts,
              detail: '$timeoutsPerTeamPerHalf per half · ${timeoutSeconds}s',
              onToggle: onTimeoutToggle,
              child: hasTimeouts
                  ? Column(
                      spacing: 4,
                      children: [
                        SettingStepper(
                          label: 'Per team per half',
                          value: timeoutsPerTeamPerHalf,
                          suffix: '',
                          min: 0,
                          max: 4,
                          step: 1,
                          onChanged: onTimeoutsPerHalfChanged,
                        ),
                        SettingStepper(
                          label: 'Durata',
                          value: timeoutSeconds,
                          suffix: 'sec',
                          min: 30,
                          max: 180,
                          step: 15,
                          onChanged: onTimeoutSecondsChanged,
                        ),
                      ],
                    )
                  : null,
            ),
            StatsSettingsSelector(
              enabledStatTypes: enabledStatTypes,
              onToggle: onToggleStat,
            ),
          ],
        ),
      ),
    );
  }
}
