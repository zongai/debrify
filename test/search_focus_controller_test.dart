import 'package:debrify/widgets/search/search_focus_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('initial focus prefers first suggestion', (tester) async {
    final field = FocusNode(debugLabel: 'field');
    final s0 = FocusNode(debugLabel: 's0');
    final c = SearchFocusController(field: field);
    addTearDown(() {
      // Controller disposes field
      c.dispose();
      s0.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(focusNode: field, child: const SizedBox(width: 8, height: 8)),
            Focus(focusNode: s0, child: const SizedBox(width: 8, height: 8)),
          ],
        ),
      ),
    );

    c.registerSuggestions([s0]);
    c.applyInitialFocus();
    await tester.pump();
    expect(s0.hasFocus, isTrue);
  });

  testWidgets('save and restore result by id', (tester) async {
    final field = FocusNode(debugLabel: 'field');
    final r0 = FocusNode(debugLabel: 'r0');
    final r1 = FocusNode(debugLabel: 'r1');
    final c = SearchFocusController(field: field);
    addTearDown(() {
      c.dispose();
      r0.dispose();
      r1.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(focusNode: field, child: const SizedBox(width: 8, height: 8)),
            Focus(focusNode: r0, child: const SizedBox(width: 8, height: 8)),
            Focus(focusNode: r1, child: const SizedBox(width: 8, height: 8)),
          ],
        ),
      ),
    );

    c.registerResults([
      (id: 'a', node: r0),
      (id: 'b', node: r1),
    ]);
    c.saveResultBeforeLeave('b');
    expect(c.restoreResultFocus(), isTrue);
    await tester.pump();
    expect(r1.hasFocus, isTrue);
  });

  test('userMoved blocks initial focus', () {
    final c = SearchFocusController()..markUserMoved();
    expect(c.canApplyDefaultFocus, isFalse);
    c.dispose();
  });
}
