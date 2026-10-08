# S1b — search_screen.dart integration hooks

Source reference: upstream `lib/screens/search_screen.dart` (~20k lines, varunsalian/debrify main).
Do **not** paste the whole file into this partial tree. Apply hooks on the full checkout.

## Existing focus infrastructure (already in upstream)

| Symbol | Role |
|--------|------|
| `_rowNodes` | `List<List<FocusNode>>` board grid |
| `reconcileHomeRowFocus` | `lib/widgets/home/home_row_focus.dart` — node reuse by id |
| `focusMountedHomeNode` | `lib/widgets/home/home_continuation_focus.dart` |
| `_homePreserved` / `HomeReturnCache` | board data snapshot (not focus identity) |
| `_autoFocusedNode` | progressive auto-focus while loading |
| `_openContinueItem`, `_openTraktItem`, `_openCollectionFolder`, … | leave-Home navigations |
| `VideoPlayerLauncher.push` | player entry |

## Add imports

```dart
import 'package:debrify/services/home_focus_memory.dart';
import 'package:debrify/widgets/home/home_focus_restore.dart';
import 'package:debrify/widgets/home/rail_locked_traversal.dart';
```

## State fields

```dart
final _homeFocusGate = HomeFocusGate();
// session key: derive from ProfileSessionMemory.captureOwner()
String get _homeFocusSessionKey {
  final o = ProfileSessionMemory.captureOwner();
  return '${o.scope?.profileId ?? o.runtimeMode}:$o.lifecycleRevision';
}
```

## Hook A — save before leave

In every path that opens Detail / Player / Collection / See All from a board card, **before** Navigator / launcher:

```dart
saveHomeFocusBeforeLeave(
  sessionOwnerKey: _homeFocusSessionKey,
  rowId: rowId,   // stable section id
  itemId: itemId, // meta id
  scrollOffset: horizontalOffsetIfKnown,
);
```

Priority call sites (names from upstream):

- `_openContinueItem`
- `_openTraktItem` / `_openSimklItem` / `_openMdblistCwItem` / `_openSimklCwItem`
- `_openCollectionFolder` / `_openCollectionScreen`
- any catalog card `onTap` / OK handler that pushes detail
- `VideoPlayerLauncher.push` entry from board if it skips detail

## Hook B — user moved

Where board focus changes from D-pad (or add a single `Focus` listener on the board scope):

```dart
_homeFocusGate.markUserMoved();
```

Coordinate with `_autoFocusedNode`: once the user has moved, stop auto-promoting newer rows (`_autoFocusedNode` logic around progressive load).

## Hook C — restore on return

After route pop back to Search/Home and rows are mounted + `_rowNodes` reconciled:

```dart
// Build HomeFocusRowMap from current section ids + _rowNodes
restoreHomeFocus(
  sessionOwnerKey: _homeFocusSessionKey,
  rows: rowMap,
  gate: _homeFocusGate,
  focusDefaultEntry: _focusDefaultHomeEntry, // existing or Hero/first card
);
```

Prefer running after the same place that currently re-requests focus on return / `HomeReturnCache.take`.

## Hook D — async commit

At end of board batch apply (where `reconcileHomeRowFocus` updates `_rowNodes`):

```dart
afterAsyncRowsCommitted(
  gate: _homeFocusGate,
  focusDefaultEntryIfAllowed: () { /* only if still cold */ },
);
```

Do **not** call unconditional `requestFocus` on first card after userMoved.

## Hook E — invalidation

Alongside `HomeReturnCache.invalidate()` listeners:

```dart
HomeFocusStore.instance.clear();
// or clearIfOwner(_homeFocusSessionKey)
```

## Hook F — horizontal lock (S1d)

Wrap each horizontal rail’s card row:

```dart
FocusTraversalGroup(
  policy: const RailLockedTraversalPolicy(),
  child: existingRow,
)
```

## Verification

```bash
flutter test test/home_focus_memory_test.dart test/home_focus_restoration_test.dart test/rail_locked_traversal_test.dart
# plus device: Home → Detail → Back restores same card; end-of-rail Right does not jump row
```
