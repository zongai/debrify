# Upstream compatibility (do not reinvent)

Debrify main already contains substantial TV focus infrastructure. This TV Design
System work **extends** it; it does not replace it.

## Home board

| Concern | Upstream | Our addition |
|---------|----------|--------------|
| Horizontal DPAD | `_BoardCell._handleArrows` in `search/search_stage_widgets.dart` — RIGHT stays in `rowNodes` | `RailLockedTraversalPolicy` for non-board lists only |
| Node reuse on refresh | `reconcileHomeRowFocus` | — |
| Mounted restore | `focusMountedHomeNode` | — |
| Board data snapshot | `HomeReturnCache` | — |
| **Focus identity across Detail** | (gap) | **`HomeFocusMemory` + S1b hooks on `_openItem` / `didPopNext`** |

## Detail

| Concern | Upstream | Our addition |
|---------|----------|--------------|
| Primary action anchor | `DetailFocusCoordinator.primaryEntry` + `focusEntry()` | — |
| Layout DPAD contracts | `detail_layouts_dpad_test`, per-layout arrows | — |
| Progressive first paint (Android TV) | progressive loading work | — |
| **Async steal / late enable** | partial | **`DetailFocusGate`** — use when recommendations/sources cause focus jumps; call `tryFocusPrimary(coordinator.primaryEntry)` only if `!userMoved` |

## Player

| Concern | Upstream | Our addition |
|---------|----------|--------------|
| TV nodes | `_tvRootFocus`, `_tvPlayPauseFocus`, `_tvProgressFocus` | — |
| Keys / Back | `_handleTvKey`, `PopScope` | — |
| Optional chrome state machine | — | `PlayerFocusController` for tests / new menus |

## Theme / focus chrome

| Concern | Upstream | Our addition |
|---------|----------|--------------|
| Focus expression | `theme/app_focus.dart` — `FocusTokens`, `FocusExpression` (ring, scale, lift, parallax/tvOS, …) | — |
| 10-foot spacing tokens | scattered | `TvTheme` / `TvSpace` as optional extension |
| Widget helper | existing card focus widgets | `TvFocusChrome` only if a site lacks theme focus |

**Rule:** Prefer `FocusTokens` / existing focus widgets on TV. Register `TvTheme` only for spacing/type constants, not a second cursor system.

## Search

| Concern | Upstream | Our addition |
|---------|----------|--------------|
| Mixed board + search modes | `SearchScreen` | `SearchFocusController` for keyword-result restore only |

## Merge priority (full repo)

1. Keep upstream focus behavior  
2. Ship **S1b** (`HomeFocusMemory` restore) — this was the real gap  
3. Use `DetailFocusGate` only where bugs show async steal  
4. Do not replace `_handleTvKey` or `FocusTokens`  
