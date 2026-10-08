# Full-repo merge guide (TV Design System modules)

Use this when merging the partial-tree TV work into a complete Debrify checkout.

## 1. Copy modules

```text
lib/services/home_focus_memory.dart
lib/widgets/home/home_focus_restore.dart
lib/widgets/home/home_focus_board_bridge.dart
lib/widgets/home/rail_locked_traversal.dart
lib/widgets/home/home_row_focus.dart              # only if missing/outdated
lib/widgets/home/home_continuation_focus.dart     # only if missing/outdated
lib/widgets/detail/detail_focus_gate.dart
lib/widgets/player/player_focus_controller.dart
lib/widgets/search/search_focus_controller.dart
lib/theme/tv_theme.dart

test/home_focus_memory_test.dart
test/home_focus_restoration_test.dart
test/home_focus_board_bridge_test.dart
test/rail_locked_traversal_test.dart
test/detail_focus_gate_test.dart
test/player_focus_controller_test.dart
test/search_focus_controller_test.dart
test/tv_theme_test.dart

docs/tv-design-system.md
docs/tv-design-system/*
```

Resolve conflicts on `home_row_focus.dart` / `home_continuation_focus.dart` by **keeping upstream** if both exist; our copies match upstream main.

## 2. Apply S1b (Home)

```bash
# From debrify root, after modules are in place:
patch -p1 < docs/tv-design-system/s1b_search_screen.patch
# If rejects: port hunks manually from the patch file (paths are a/lib/screens/...)
```

Then optionally:

- Wrap each horizontal rail: `FocusTraversalGroup(policy: const RailLockedTraversalPolicy(), child: ...)`
- On `HomeReturnCache.invalidate` / profile switch: `HomeFocusStore.instance.clear()`
- When `_autoFocusSettled` / user moves board focus: `_homeFocusBridge.markUserMoved()`

## 3. S2 Detail (map to existing layouts)

Upstream already has `detail_layouts_dpad_test` and progressive Android TV loading.

Wire **one** `DetailFocusGate` per detail route state:

| Call site | Action |
|-----------|--------|
| First frame / opening complete | `gate.tryFocusPrimary(playFocusNode)` |
| Sources become ready | `gate.onPrimaryBecameEnabled(playFocusNode)` |
| Recommendations/cast setState | do **not** `requestFocus` |
| Focus change listener | `gate.markUserMoved()` |

Files (typical): Showcase / merged series / `CatalogItemDetailScreen` / `detail_layout_*`.

Keep existing DPAD episode contracts; only add the gate.

## 4. S3 Player (align, do not rewrite)

Upstream `video_player_screen.dart` already has:

- `_tvRootFocus`, `_tvPlayPauseFocus`, `_tvProgressFocus`
- `_handleTvKey`, PopScope for Back/Menu
- Overlay show/hide and progress scrub focus

**Do not** replace that stack in the first pass.

Optional alignment with `PlayerFocusController`:

- Treat “controls visible” / “menu open” / “root only” as chrome states  
- Ensure Back layers match: menu/panel → hide bar → pop route (PopScope already owns last step)  
- When adding new TV menus, prefer explicit focus nodes + handled keys over ad-hoc requests  

Use `PlayerFocusController` for **new** TV chrome or tests; migrate gradually.

## 5. S4 Search mode

Upstream Search mixes board + keyword/catalog modes in the same screen.

Wire `SearchFocusController` for **keyword/catalog search phase** only:

- Default focus: first suggestion if any, else field  
- `saveResultBeforeLeave` before opening detail from a result  
- On return: `restoreResultFocus()`  
- Keyboard edge Down → `focusFirstResult()`

Avoid fighting Home board auto-focus (`_autoFocusedNode`).

## 6. S5 Theme

```dart
ThemeData(
  extensions: const [TvTheme.defaults],
  // ...
)
```

on TV entrypoints (main TV branch). Wrap posters/primary actions with `TvFocusChrome` incrementally; do not strip existing collection glow.

## 7. Verify

```bash
flutter test test/home_focus_*.dart test/rail_locked_traversal_test.dart \
  test/detail_focus_gate_test.dart test/player_focus_controller_test.dart \
  test/search_focus_controller_test.dart test/tv_theme_test.dart

# Device
# Home → Detail → Back restores card
# Rail Right at end does not jump row (after S1d wrap)
# Player Back layers still work
```

## Priority order

1. Modules copy + tests green  
2. S1b patch  
3. S1d rail wraps  
4. S2 gate on primary detail path  
5. S5 theme registration  
6. S4 search phase  
7. S3 gradual alignment only if Back layers regress  
