# TV Design System — Implementation Progress

Updated: 2026-10-09 — **foundation + S1b complete for this environment**

## Done

| Work | Location |
|------|----------|
| Spec S1–S5 | `docs/tv-design-system.md` |
| Upstream compatibility map | `docs/tv-design-system/UPSTREAM_COMPATIBILITY.md` |
| Full-repo merge guide | `docs/tv-design-system/FULL_REPO_MERGE_GUIDE.md` |
| S1a modules + tests | `lib/services/home_focus_memory.dart`, `lib/widgets/home/home_focus_restore.dart`, tests |
| S1b applied | `lib/screens/search_screen.dart` + patch |
| Board bridge | `lib/widgets/home/home_focus_board_bridge.dart` |
| S1d | Upstream `_BoardCell` already locks horizontal; policy helper kept |
| S2 gate module | `lib/widgets/detail/detail_focus_gate.dart` (pairs with upstream `DetailFocusCoordinator`) |
| S3 helper | `lib/widgets/player/player_focus_controller.dart` (do not replace `_handleTvKey`) |
| S4 helper | `lib/widgets/search/search_focus_controller.dart` |
| S5 shell | `lib/theme/tv_theme.dart` — prefer upstream `app_focus.dart` `FocusTokens` for cursor |
| Upstream focus theme reference | `lib/theme/app_focus.dart` (copied) |
| search part file | `lib/screens/search/search_stage_widgets.dart` |

## Not done here (needs full compile + device)

- Flutter analyze / test execution (no SDK in this environment)
- Device QA path Home → Detail → Back
- Optional DetailFocusGate call sites inside showcase layouts
- TvTheme registration on root ThemeData (optional; FocusTokens primary)
- Keyword-search phase SearchFocusController wiring

## Stop condition for this sandbox

Further “continue” without a **complete, buildable** `lib/` only duplicates docs.  
Next productive step is merge into full Debrify + run tests/device per `FULL_REPO_MERGE_GUIDE.md` and `UPSTREAM_COMPATIBILITY.md`.
