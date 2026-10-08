import 'package:flutter/widgets.dart';

import '../../services/home_focus_memory.dart';

/// One focusable card on a Home rail after reconcile.
class HomeCardFocusHandle {
  const HomeCardFocusHandle({
    required this.itemId,
    required this.node,
  });

  final String itemId;
  final FocusNode node;

  bool get isMounted => node.context != null;
}

/// rowId → ordered cards (typically after [reconcileHomeRowFocus]).
typedef HomeFocusRowMap = Map<String, List<HomeCardFocusHandle>>;

/// Restore focus when the Home board is visible and rows are mounted.
///
/// Call after `reconcileHomeRowFocus` (or equivalent). Prefer this on
/// route-return; for cold start with no memory it applies default entry once
/// via [HomeFocusGate.canApplyDefaultFocus].
void restoreHomeFocus({
  required String sessionOwnerKey,
  required HomeFocusRowMap rows,
  required HomeFocusGate gate,
  required VoidCallback focusDefaultEntry,
  HomeFocusStore? store,
}) {
  final memory = (store ?? HomeFocusStore.instance).take(sessionOwnerKey);
  if (memory == null) {
    if (gate.canApplyDefaultFocus) {
      focusDefaultEntry();
      gate.markInitialFocusApplied();
    }
    return;
  }

  final rail = rows[memory.rowId];
  if (rail == null || rail.isEmpty) {
    if (gate.canApplyDefaultFocus) {
      focusDefaultEntry();
      gate.markInitialFocusApplied();
    }
    return;
  }

  HomeCardFocusHandle? match;
  for (final card in rail) {
    if (card.itemId == memory.itemId) {
      match = card;
      break;
    }
  }

  HomeCardFocusHandle? target;
  if (match != null && match.isMounted) {
    target = match;
  } else {
    for (final card in rail) {
      if (card.isMounted) {
        target = card;
        break;
      }
    }
  }

  if (target != null) {
    target.node.requestFocus();
    gate.markInitialFocusApplied();
    return;
  }

  if (gate.canApplyDefaultFocus) {
    focusDefaultEntry();
    gate.markInitialFocusApplied();
  }
}

/// After async row reconcile/commit: only apply default entry if allowed.
///
/// When [HomeFocusGate.userMoved] is true this is a no-op (no requestFocus).
void afterAsyncRowsCommitted({
  required HomeFocusGate gate,
  required VoidCallback focusDefaultEntryIfAllowed,
}) {
  if (gate.canApplyDefaultFocus) {
    focusDefaultEntryIfAllowed();
    gate.markInitialFocusApplied();
  }
}
