import 'package:flutter/widgets.dart';

import '../../services/home_focus_memory.dart';
import 'home_focus_restore.dart';

/// Helpers for wiring Home board focus (S1b) without depending on SearchScreen.
///
/// Upstream board stores:
/// - section row ids via `_sectionRowId(section)`
/// - item ids via `item.id` (and type) inside `reconcileHomeRowFocus` identities
/// - nodes in `_rowNodes` aligned with sections/items
class HomeFocusBoardBridge {
  HomeFocusBoardBridge({
    HomeFocusStore? store,
    HomeFocusGate? gate,
  })  : store = store ?? HomeFocusStore.instance,
        gate = gate ?? HomeFocusGate();

  final HomeFocusStore store;
  final HomeFocusGate gate;

  /// Build a session key compatible with profile lifecycle.
  ///
  /// Prefer passing the same string derived from [ProfileSessionOwner] in the
  /// full app, e.g. `'${scope.profileId}:${lifecycleRevision}'`.
  static String sessionKey({
    required String profileId,
    required int lifecycleRevision,
  }) =>
      '$profileId:$lifecycleRevision';

  /// Content identity matching upstream reconcile encoding components.
  static String itemFocusId({
    required String type,
    required String id,
  }) =>
      '$type::$id';

  /// Save before leaving the board for Detail / Player / folder browser.
  void saveBeforeLeave({
    required String sessionOwnerKey,
    required String rowId,
    required String itemType,
    required String itemId,
    double? scrollOffset,
  }) {
    saveHomeFocusBeforeLeave(
      sessionOwnerKey: sessionOwnerKey,
      rowId: rowId,
      itemId: itemFocusId(type: itemType, id: itemId),
      scrollOffset: scrollOffset,
      store: store,
    );
  }

  void markUserMoved() => gate.markUserMoved();

  void resetGateForFreshBoard() => gate.resetForFreshBoard();

  void clearMemory() => store.clear();

  void clearMemoryIfOwner(String sessionOwnerKey) =>
      store.clearIfOwner(sessionOwnerKey);

  /// Restore after rows are mounted. [rowIds] length must match [rowNodes].
  /// Each [itemIds] row lists identities from [itemFocusId].
  void restore({
    required String sessionOwnerKey,
    required List<String> rowIds,
    required List<List<String>> itemIds,
    required List<List<FocusNode>> rowNodes,
    required VoidCallback focusDefaultEntry,
  }) {
    final map = <String, List<HomeCardFocusHandle>>{};
    for (var r = 0; r < rowIds.length; r++) {
      if (r >= rowNodes.length || r >= itemIds.length) break;
      final nodes = rowNodes[r];
      final ids = itemIds[r];
      final handles = <HomeCardFocusHandle>[];
      for (var c = 0; c < nodes.length && c < ids.length; c++) {
        handles.add(HomeCardFocusHandle(itemId: ids[c], node: nodes[c]));
      }
      map[rowIds[r]] = handles;
    }
    restoreHomeFocus(
      sessionOwnerKey: sessionOwnerKey,
      rows: map,
      gate: gate,
      focusDefaultEntry: focusDefaultEntry,
      store: store,
    );
  }

  void afterAsyncCommit({required VoidCallback focusDefaultEntryIfAllowed}) {
    afterAsyncRowsCommitted(
      gate: gate,
      focusDefaultEntryIfAllowed: focusDefaultEntryIfAllowed,
    );
  }
}
