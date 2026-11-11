import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mauriguide/main.dart';
import 'package:mauriguide/data.dart';

void main() {
  test('Planner respects daily budget and does not repeat stops', () {
    final plan = planTrip(7, 300, {'Culture'});
    expect(plan.length, 7);
    final ids = plan.expand((d) => d).map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final day in plan) {
      expect(
        day.fold<int>(0, (sum, p) => sum + p.cost),
        lessThanOrEqualTo(300),
      );
    }
  });
  test('Matching interests are ranked first', () {
    expect(recommend({'Culture'}, 1500).first.category, 'Culture');
  });
  testWidgets('Discovery and itinerary generation work', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MauriGuide());
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('A little island.\nEndless possibilities.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Plan my adventure'));
    await tester.pump();
    await tester.tap(find.text('Generate itinerary'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('DAY 1'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('DAY 1'), findsOneWidget);
  });
}
