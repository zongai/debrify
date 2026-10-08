import 'package:debrify/services/home_focus_memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HomeFocusStore store;

  setUp(() {
    store = HomeFocusStore.createForTest();
  });

  group('HomeFocusStore', () {
    test('take consumes matching memory', () {
      store.save(
        const HomeFocusMemory(
          sessionOwnerKey: 's1',
          rowId: 'continue_watching',
          itemId: 'tt123',
        ),
      );
      final m = store.take('s1');
      expect(m?.itemId, 'tt123');
      expect(m?.rowId, 'continue_watching');
      expect(store.take('s1'), isNull);
      expect(store.peek(), isNull);
    });

    test('take rejects other session and leaves memory', () {
      store.save(
        const HomeFocusMemory(
          sessionOwnerKey: 's1',
          rowId: 'r',
          itemId: 'i',
        ),
      );
      expect(store.take('s2'), isNull);
      expect(store.peek()?.sessionOwnerKey, 's1');
    });

    test('clearIfOwner only clears matching session', () {
      store.save(
        const HomeFocusMemory(
          sessionOwnerKey: 's1',
          rowId: 'r',
          itemId: 'i',
        ),
      );
      store.clearIfOwner('s2');
      expect(store.peek(), isNotNull);
      store.clearIfOwner('s1');
      expect(store.peek(), isNull);
    });

    test('saveHomeFocusBeforeLeave writes through store', () {
      saveHomeFocusBeforeLeave(
        sessionOwnerKey: 's1',
        rowId: 'bilibili_pgc_anime',
        itemId: 'ep-9',
        scrollOffset: 120,
        store: store,
      );
      final m = store.take('s1');
      expect(m?.rowId, 'bilibili_pgc_anime');
      expect(m?.itemId, 'ep-9');
      expect(m?.scrollOffset, 120);
    });

    test('equality uses all fields', () {
      const a = HomeFocusMemory(
        sessionOwnerKey: 's',
        rowId: 'r',
        itemId: 'i',
        scrollOffset: 1,
      );
      const b = HomeFocusMemory(
        sessionOwnerKey: 's',
        rowId: 'r',
        itemId: 'i',
        scrollOffset: 1,
      );
      const c = HomeFocusMemory(
        sessionOwnerKey: 's',
        rowId: 'r',
        itemId: 'other',
      );
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('HomeFocusGate', () {
    test('blocks default after user moved', () {
      final gate = HomeFocusGate();
      expect(gate.canApplyDefaultFocus, isTrue);
      gate.markUserMoved();
      expect(gate.canApplyDefaultFocus, isFalse);
    });

    test('allows only one initial default', () {
      final gate = HomeFocusGate();
      expect(gate.canApplyDefaultFocus, isTrue);
      gate.markInitialFocusApplied();
      expect(gate.canApplyDefaultFocus, isFalse);
    });

    test('resetForFreshBoard clears flags', () {
      final gate = HomeFocusGate()
        ..markUserMoved()
        ..markInitialFocusApplied();
      gate.resetForFreshBoard();
      expect(gate.userMoved, isFalse);
      expect(gate.didInitialFocus, isFalse);
      expect(gate.canApplyDefaultFocus, isTrue);
    });
  });
}
