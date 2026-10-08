import 'package:flutter/foundation.dart';

/// Stable focus identity for the Home board (TV / D-pad).
///
/// Prefer content ids over list indices so row reorder and async inserts can
/// restore the same card after returning from Detail / Player / See All.
@immutable
class HomeFocusMemory {
  const HomeFocusMemory({
    required this.sessionOwnerKey,
    required this.rowId,
    required this.itemId,
    this.scrollOffset,
  });

  /// Must match the profile/session key used by [HomeReturnCache] /
  /// ProfileSession when those are available in the full tree.
  final String sessionOwnerKey;

  /// Stable rail id, e.g. `continue_watching`, catalog id, `collection:<id>`.
  final String rowId;

  /// Stable content id within the rail (never a volatile list index alone).
  final String itemId;

  /// Optional horizontal offset within the rail.
  final double? scrollOffset;

  @override
  bool operator ==(Object other) =>
      other is HomeFocusMemory &&
      other.sessionOwnerKey == sessionOwnerKey &&
      other.rowId == rowId &&
      other.itemId == itemId &&
      other.scrollOffset == scrollOffset;

  @override
  int get hashCode => Object.hash(sessionOwnerKey, rowId, itemId, scrollOffset);

  @override
  String toString() =>
      'HomeFocusMemory($sessionOwnerKey, row=$rowId, item=$itemId, '
      'scroll=$scrollOffset)';
}

/// Session-scoped store for the last Home focus. [take] consumes the value.
class HomeFocusStore {
  HomeFocusStore._();

  static final HomeFocusStore instance = HomeFocusStore._();

  HomeFocusMemory? _memory;

  /// Isolated instance for unit tests (does not touch [instance]).
  @visibleForTesting
  static HomeFocusStore createForTest() => HomeFocusStore._();

  void save(HomeFocusMemory memory) {
    _memory = memory;
  }

  /// Returns and clears memory when [sessionOwnerKey] matches; otherwise null.
  HomeFocusMemory? take(String sessionOwnerKey) {
    final m = _memory;
    if (m == null || m.sessionOwnerKey != sessionOwnerKey) {
      return null;
    }
    _memory = null;
    return m;
  }

  HomeFocusMemory? peek() => _memory;

  void clear() {
    _memory = null;
  }

  /// Call when HomeReturnCache / addons / profile session invalidate for [sessionOwnerKey].
  void clearIfOwner(String sessionOwnerKey) {
    if (_memory?.sessionOwnerKey == sessionOwnerKey) {
      clear();
    }
  }
}

/// Prevents async row commits from stealing focus after the user has moved.
class HomeFocusGate {
  bool userMoved = false;
  bool didInitialFocus = false;

  void markUserMoved() {
    userMoved = true;
  }

  void resetForFreshBoard() {
    userMoved = false;
    didInitialFocus = false;
  }

  /// Cold start / no memory: allow a single default focus application.
  bool get canApplyDefaultFocus => !userMoved && !didInitialFocus;

  void markInitialFocusApplied() {
    didInitialFocus = true;
  }
}

/// Convenience: persist focus before leaving Home for Detail / Player / etc.
void saveHomeFocusBeforeLeave({
  required String sessionOwnerKey,
  required String rowId,
  required String itemId,
  double? scrollOffset,
  HomeFocusStore? store,
}) {
  (store ?? HomeFocusStore.instance).save(
    HomeFocusMemory(
      sessionOwnerKey: sessionOwnerKey,
      rowId: rowId,
      itemId: itemId,
      scrollOffset: scrollOffset,
    ),
  );
}
