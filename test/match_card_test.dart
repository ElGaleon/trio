import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/shared/match_card.dart';

void main() {
  testWidgets('match card keeps detailed data out of the main list', (
    tester,
  ) async {
    final match = ScrimmageMatch(
      id: 'match-1',
      createdAt: DateTime(2026, 5, 26),
      teamAIds: const ['a', 'b', 'c'],
      teamBIds: const ['d', 'e', 'f'],
      scoreA: 21,
      scoreB: 18,
      initialRatings: const {'a': 1000},
      finalRatings: const {'a': 1016},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchCard(match: match, onEdit: () {}, onDelete: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('21'), findsWidgets);
    expect(find.text('18'), findsWidgets);
    expect(find.byIcon(Icons.sports_score), findsNothing);
    expect(find.textContaining('ELO'), findsNothing);
    expect(find.textContaining('+16'), findsNothing);
  });
}
