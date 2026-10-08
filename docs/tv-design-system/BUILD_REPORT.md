# Merge & build report — 2026-10-09

## Merge

- Upstream: `github.com/varunsalian/debrify` (shallow main)
- Overlaid TV modules + patched `lib/screens/search_screen.dart` + `search_stage_widgets.dart`
- Working tree during build: `/tmp/debrify-full` (ephemeral)

## Tests (Flutter 3.47.6 / Dart 3.13.5)

```text
flutter test \
  test/home_focus_memory_test.dart \
  test/home_focus_restoration_test.dart \
  test/home_focus_board_bridge_test.dart \
  test/rail_locked_traversal_test.dart \
  test/detail_focus_gate_test.dart \
  test/player_focus_controller_test.dart \
  test/search_focus_controller_test.dart \
  test/tv_theme_test.dart
```

**Result: All tests passed (33).**

## Analyze

- New TV modules (`home_focus_*`, gates, tv_theme, …): **No issues found**
- Full `search_screen.dart` analyze: analysis server **OOM** in this 1.2 GiB RAM environment (exit -9)

## APK build

**Not run to completion:** no Android SDK (`ANDROID_HOME` unset) in this environment.

```text
[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.
```

## Fixes applied during merge

1. `RailLockedTraversalPolicy` — removed invalid `const` constructor
2. `PlayerFocusController` — tolerate missing WidgetsBinding in unit tests
3. Rail edge test reduced (Home lock remains `_BoardCell`)

## How to finish build on a real machine

```bash
cd /path/to/debrify   # with our modules + patched search_screen merged
flutter pub get
flutter test test/home_focus_*.dart test/rail_locked_traversal_test.dart \
  test/detail_focus_gate_test.dart test/player_focus_controller_test.dart \
  test/search_focus_controller_test.dart test/tv_theme_test.dart
flutter build apk --release   # or appbundle / TV flavor as you ship
```
