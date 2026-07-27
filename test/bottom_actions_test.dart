import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skrim/src/features/live_stats/presentation/live_stats/bottom_actions.dart';

void main() {
  testWidgets(
    'BottomActions shows PULL button when onPull is provided regardless of oursOnOffense',
    (tester) async {
      // 1. oursOnOffense = true, onPull != null
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomActions(
              oursOnOffense: true,
              showThrowaway: true,
              timeoutLabel: 'TIMEOUT',
              onGoal: () {},
              onOpponentGoal: () {},
              onOpponentError: () {},
              onPull: () {},
              onTimeout: () {},
              onInjury: () {},
              onUndo: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PULL'), findsOneWidget);

      // 2. oursOnOffense = false, onPull != null
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomActions(
              oursOnOffense: false,
              showThrowaway: true,
              timeoutLabel: 'TIMEOUT',
              onGoal: () {},
              onOpponentGoal: () {},
              onOpponentError: () {},
              onPull: () {},
              onTimeout: () {},
              onInjury: () {},
              onUndo: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PULL'), findsOneWidget);

      // 3. onPull = null
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomActions(
              oursOnOffense: false,
              showThrowaway: true,
              timeoutLabel: 'TIMEOUT',
              onGoal: () {},
              onOpponentGoal: () {},
              onOpponentError: () {},
              onPull: null,
              onTimeout: () {},
              onInjury: () {},
              onUndo: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PULL'), findsNothing);
    },
  );
}
