import 'package:debrify/widgets/detail/detail_focus_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tryFocusPrimary focuses when gate allows', (tester) async {
    final primary = FocusNode(debugLabel: 'play');
    addTearDown(primary.dispose);
    final gate = DetailFocusGate();

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          focusNode: primary,
          child: const SizedBox(width: 8, height: 8),
        ),
      ),
    );

    gate.tryFocusPrimary(primary);
    await tester.pump();
    expect(primary.hasFocus, isTrue);
    expect(gate.didInitialFocus, isTrue);
  });

  testWidgets('tryFocusPrimary no-ops after user moved', (tester) async {
    final primary = FocusNode(debugLabel: 'play');
    final other = FocusNode(debugLabel: 'other');
    addTearDown(() {
      primary.dispose();
      other.dispose();
    });
    final gate = DetailFocusGate();

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(focusNode: primary, child: const SizedBox(width: 8, height: 8)),
            Focus(focusNode: other, child: const SizedBox(width: 8, height: 8)),
          ],
        ),
      ),
    );

    other.requestFocus();
    await tester.pump();
    gate.markUserMoved();
    gate.tryFocusPrimary(primary);
    await tester.pump();
    expect(other.hasFocus, isTrue);
    expect(primary.hasFocus, isFalse);
  });

  testWidgets('onPrimaryBecameEnabled focuses only if never moved', (
    tester,
  ) async {
    final primary = FocusNode(debugLabel: 'play');
    addTearDown(primary.dispose);
    final gate = DetailFocusGate();

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          focusNode: primary,
          child: const SizedBox(width: 8, height: 8),
        ),
      ),
    );

    gate.onPrimaryBecameEnabled(primary);
    await tester.pump();
    expect(primary.hasFocus, isTrue);

    final gate2 = DetailFocusGate()..markUserMoved();
    primary.unfocus();
    await tester.pump();
    gate2.onPrimaryBecameEnabled(primary);
    await tester.pump();
    expect(primary.hasFocus, isFalse);
  });

  test('onAsyncSectionReady does not throw or change flags', () {
    final gate = DetailFocusGate();
    gate.onAsyncSectionReady();
    expect(gate.userMoved, isFalse);
    expect(gate.didInitialFocus, isFalse);
  });
}
