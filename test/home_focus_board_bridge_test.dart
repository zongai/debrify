import 'package:debrify/widgets/home/home_focus_board_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sessionKey and itemFocusId are stable', () {
    expect(
      HomeFocusBoardBridge.sessionKey(profileId: 'p1', lifecycleRevision: 3),
      'p1:3',
    );
    expect(
      HomeFocusBoardBridge.itemFocusId(type: 'series', id: 'tt1'),
      'series::tt1',
    );
  });

  testWidgets('save and restore via bridge', (tester) async {
    final bridge = HomeFocusBoardBridge();
    final a = FocusNode(debugLabel: 'a');
    final b = FocusNode(debugLabel: 'b');
    addTearDown(() {
      a.dispose();
      b.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(focusNode: a, child: const SizedBox(width: 8, height: 8)),
            Focus(focusNode: b, child: const SizedBox(width: 8, height: 8)),
          ],
        ),
      ),
    );

    bridge.saveBeforeLeave(
      sessionOwnerKey: 'p:1',
      rowId: 'continue_watching',
      itemType: 'movie',
      itemId: 'tt-b',
    );

    bridge.restore(
      sessionOwnerKey: 'p:1',
      rowIds: ['continue_watching'],
      itemIds: [
        [
          HomeFocusBoardBridge.itemFocusId(type: 'movie', id: 'tt-a'),
          HomeFocusBoardBridge.itemFocusId(type: 'movie', id: 'tt-b'),
        ],
      ],
      rowNodes: [
        [a, b],
      ],
      focusDefaultEntry: () => a.requestFocus(),
    );
    await tester.pump();
    expect(b.hasFocus, isTrue);
  });

  test('afterAsyncCommit respects userMoved', () {
    final bridge = HomeFocusBoardBridge();
    bridge.markUserMoved();
    var n = 0;
    bridge.afterAsyncCommit(focusDefaultEntryIfAllowed: () => n++);
    expect(n, 0);
  });
}
