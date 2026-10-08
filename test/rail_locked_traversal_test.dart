import 'package:debrify/widgets/home/rail_locked_traversal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Home board horizontal lock is enforced by _BoardCell, not this policy.
  // Keep a minimal in-rail move test only.
  testWidgets('right from first card moves to second in rail', (tester) async {
    final a = FocusNode(debugLabel: 'a');
    final b = FocusNode(debugLabel: 'b');
    addTearDown(() {
      a.dispose();
      b.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: FocusTraversalGroup(
          policy: RailLockedTraversalPolicy(),
          child: Row(
            children: [
              Focus(focusNode: a, child: const SizedBox(width: 40, height: 40)),
              Focus(focusNode: b, child: const SizedBox(width: 40, height: 40)),
            ],
          ),
        ),
      ),
    );

    a.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(b.hasFocus, isTrue);
  });
}
