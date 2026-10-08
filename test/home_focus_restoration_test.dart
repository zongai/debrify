import 'package:debrify/services/home_focus_memory.dart';
import 'package:debrify/widgets/home/home_focus_restore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HomeFocusStore store;
  late HomeFocusGate gate;

  setUp(() {
    store = HomeFocusStore.createForTest();
    gate = HomeFocusGate();
  });

  testWidgets('restores focus to saved itemId', (tester) async {
    final nodeA = FocusNode(debugLabel: 'a');
    final nodeB = FocusNode(debugLabel: 'b');
    addTearDown(() {
      nodeA.dispose();
      nodeB.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(focusNode: nodeA, child: const SizedBox(width: 8, height: 8)),
            Focus(focusNode: nodeB, child: const SizedBox(width: 8, height: 8)),
          ],
        ),
      ),
    );

    store.save(
      const HomeFocusMemory(
        sessionOwnerKey: 's1',
        rowId: 'row:cw',
        itemId: 'item-b',
      ),
    );

    final rows = <String, List<HomeCardFocusHandle>>{
      'row:cw': [
        HomeCardFocusHandle(itemId: 'item-a', node: nodeA),
        HomeCardFocusHandle(itemId: 'item-b', node: nodeB),
      ],
    };

    var defaultCalls = 0;
    restoreHomeFocus(
      sessionOwnerKey: 's1',
      rows: rows,
      gate: gate,
      store: store,
      focusDefaultEntry: () {
        defaultCalls++;
        nodeA.requestFocus();
      },
    );
    await tester.pump();

    expect(nodeB.hasFocus, isTrue);
    expect(defaultCalls, 0);
    expect(store.peek(), isNull);
  });

  testWidgets('falls back to first mounted card when item missing', (
    tester,
  ) async {
    final nodeA = FocusNode(debugLabel: 'a');
    final nodeB = FocusNode(debugLabel: 'b');
    addTearDown(() {
      nodeA.dispose();
      nodeB.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(focusNode: nodeA, child: const SizedBox(width: 8, height: 8)),
            Focus(focusNode: nodeB, child: const SizedBox(width: 8, height: 8)),
          ],
        ),
      ),
    );

    store.save(
      const HomeFocusMemory(
        sessionOwnerKey: 's1',
        rowId: 'row:cw',
        itemId: 'gone',
      ),
    );

    restoreHomeFocus(
      sessionOwnerKey: 's1',
      rows: {
        'row:cw': [
          HomeCardFocusHandle(itemId: 'item-a', node: nodeA),
          HomeCardFocusHandle(itemId: 'item-b', node: nodeB),
        ],
      },
      gate: gate,
      store: store,
      focusDefaultEntry: () => nodeB.requestFocus(),
    );
    await tester.pump();

    expect(nodeA.hasFocus, isTrue);
  });

  testWidgets('missing row uses default entry when gate allows', (tester) async {
    final nodeA = FocusNode(debugLabel: 'a');
    addTearDown(nodeA.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          focusNode: nodeA,
          child: const SizedBox(width: 8, height: 8),
        ),
      ),
    );

    store.save(
      const HomeFocusMemory(
        sessionOwnerKey: 's1',
        rowId: 'row:missing',
        itemId: 'x',
      ),
    );

    var defaultCalls = 0;
    restoreHomeFocus(
      sessionOwnerKey: 's1',
      rows: const {},
      gate: gate,
      store: store,
      focusDefaultEntry: () {
        defaultCalls++;
        nodeA.requestFocus();
      },
    );
    await tester.pump();

    expect(defaultCalls, 1);
    expect(nodeA.hasFocus, isTrue);
  });

  test('afterAsyncRowsCommitted is no-op when user moved', () {
    gate.markUserMoved();
    var called = 0;
    afterAsyncRowsCommitted(
      gate: gate,
      focusDefaultEntryIfAllowed: () => called++,
    );
    expect(called, 0);
  });

  test('afterAsyncRowsCommitted applies default once when allowed', () {
    var called = 0;
    afterAsyncRowsCommitted(
      gate: gate,
      focusDefaultEntryIfAllowed: () => called++,
    );
    expect(called, 1);
    afterAsyncRowsCommitted(
      gate: gate,
      focusDefaultEntryIfAllowed: () => called++,
    );
    expect(called, 1);
  });

  testWidgets('no memory and user moved does not default focus', (tester) async {
    final nodeA = FocusNode(debugLabel: 'a');
    addTearDown(nodeA.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          focusNode: nodeA,
          child: const SizedBox(width: 8, height: 8),
        ),
      ),
    );

    gate.markUserMoved();
    var defaultCalls = 0;
    restoreHomeFocus(
      sessionOwnerKey: 's1',
      rows: {
        'row:cw': [HomeCardFocusHandle(itemId: 'a', node: nodeA)],
      },
      gate: gate,
      store: store,
      focusDefaultEntry: () {
        defaultCalls++;
        nodeA.requestFocus();
      },
    );
    await tester.pump();

    expect(defaultCalls, 0);
  });
}
