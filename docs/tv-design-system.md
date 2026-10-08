# Debrify TV Design System — Android TV + tvOS

**Status:** Spec complete (2026-10-09)  
**Priority:** UX > Focus / Navigation > Information Architecture > Visual > Animation  
**Rule:** Do not scale mobile/PC UI to TV. Keep 70–80% visual system shared; allow 20–30% platform-native interaction.

Related existing work:

- `docs/tv-performance-research.md`, `tv-performance-work.md`, `tv-progressive-loading-work.md`
- `docs/collection-focus-effects-review.md`
- Tests: `home_row_focus_test`, `home_continuation_focus_test`, `home_return_cache_test`, `detail_layouts_dpad_test`, `collection_focus_*`, `debrify_tv_style_test`

---

## 1. Principles (10-foot)

- Readable from ~3m; large targets; clear hierarchy
- Focus always visible and predictable
- D-pad / Siri Remote complete core flows without touch
- Minimum steps: Browse → Detail → Play
- No focus trap, dead end, jump, or infinite loop
- Async load must not steal focus after the user has moved
- Back is layered (panel → chrome → route)

### Platform split

| Concern | Shared | Android TV | tvOS |
|---------|--------|------------|------|
| Color, type scale, spacing, card sizes | Yes | — | — |
| Focus visibility | Yes (obvious) | Explicit ring + optional scale | Focus Engine + guides |
| Navigation | Same IA | D-pad + FocusTraversal | Focus Engine + FocusGuide |
| Back | Same layers | Back key | Menu |
| Motion | Short | Prefer shorter; simplify while moving | Slightly longer focus transition OK |
| Detail first paint | Primary CTA early | Progressive loading (already) | Opening animation OK if focus ends on Play |

---

## 2. Information architecture

```
Shell (Nav)
└── Home: optional Hero + vertical Content Rails
└── Detail: Hero + Primary CTA + secondary + episodes + related
└── Player: surface + optional chrome + sub-panels
└── Search: field + suggestions + filters + results + keyboard
```

Detail action priority: **Play > resume progress > title/meta > overview > sources > related**.

---

## 3. Focus rules (global)

### States

`Default → Focused → Pressed → Selected` (+ Disabled / Loading / Error)

Focused visual: at most two primary signals (e.g. **scale 1.05–1.08 + border**). Collection glow/video is optional enhancement and must not replace the base ring.

### Gate

```
userMoved = false
didInitialFocus = false

on user-directed focus change → userMoved = true
async section ready → setState only; never requestFocus to a "default"
default/entry focus only if !userMoved && !didInitialFocus
```

### Identity

Persist **rowId + itemId** (never list index alone). Session owner must align with `HomeReturnCache` / profile session.

---

## 4. Sprint map

| Sprint | Scope | Exit criteria |
|--------|--------|----------------|
| **S1** | Home focus memory, horizontal lock, no async steal | Back restores card; no row jump |
| **S2** | Detail default Play, episodes bridge, no steal | Zero down-presses to Play when ready |
| **S3** | Player chrome 3-state, 3-layer Back | Remote-only transport + safe exit |
| **S4** | Search suggestions-first, keyboard↔results | Search without typing; no trap |
| **S5** | TvTheme tokens + shared focus chrome | TV paths not using mobile type sizes |

---

## 5. S1 — Home

### Direction contract

| From | Up | Down | Left | Right | OK | Back |
|------|----|------|------|-------|----|------|
| Nav | prev | content default | prev | next | switch tab | system |
| Hero | Nav | rail0 first card | — | — | detail/play | Nav |
| Card | prev rail | next rail | prev card | next / See All | detail | Nav / stay |
| See All | title | next rail | last card | — | grid | rail |

**Hard rules**

- Horizontal movement stays inside the current rail
- Vertical prefers same column, else first focusable in row
- Edges stop (no wrap loop)
- Return restores `rowId+itemId`

### Files

| File | Action |
|------|--------|
| `lib/services/home_focus_memory.dart` | **Add** store + gate |
| `lib/widgets/home/home_focus_restore.dart` | **Add** restore helpers (optional split) |
| `lib/widgets/home/home_row_focus.dart` | Keep reconcile; no requestFocus inside |
| `lib/widgets/home/home_continuation_focus.dart` | Restore only mounted nodes |
| `lib/services/home_return_cache.dart` | Clear focus store on same invalidations |
| `lib/screens/search_screen.dart` | save before leave; restore on visible; gate async focus; rail traversal |
| `lib/widgets/home/spotlight_board.dart` | Same save/restore API if separate focus graph |
| `lib/main.dart` / `MainPageBridge` | clear memory on profile/settings invalidation |
| `test/home_focus_memory_test.dart` | Unit |
| `test/home_focus_restoration_test.dart` | Restore + no-steal + horizontal edge |

### rowId conventions

| Row | rowId |
|-----|--------|
| Continue watching | `continue_watching` |
| Catalog | stable catalog id |
| Bilibili PGC | existing `bilibili_pgc_*` |
| Collection | `collection:<id>` |

### S1 commit slices

1. **S1a** — memory + gate + unit tests only  
2. **S1b** — save + restore hooks in board  
3. **S1c** — async no-steal gate on batch commit  
4. **S1d** — horizontal FocusTraversalGroup / edge keys  
5. **S1e** — Spotlight/collection parity + device check  

### Skeleton: `HomeFocusMemory` / store / gate

See implementation sketch in project discussion (2026-10-09). Core API:

- `HomeFocusStore.save / take / clear / clearIfOwner`
- `HomeFocusGate.markUserMoved / canApplyDefaultFocus / markInitialFocusApplied`
- `saveHomeFocusBeforeLeave(...)`
- `restoreHomeFocus(sessionOwnerKey, rows, gate, focusDefaultEntry)`
- `afterAsyncRowsCommitted(gate, focusDefaultEntryIfAllowed)`

### search_screen hook order

1. Before any push to Detail / Player / See All / Collection folder → `saveHomeFocusBeforeLeave`
2. On focus change from user → `gate.markUserMoved()`
3. After rows mounted + `reconcileHomeRowFocus` on board visible → `restoreHomeFocus`
4. End of `_fetchBoardBatch` / progressive commit → `afterAsyncRowsCommitted` (not unconditional requestFocus)
5. Alongside HomeReturnCache invalidation → `HomeFocusStore.instance.clear()`

---

## 6. S2 — Detail

### Contracts (all layouts)

| ID | Rule |
|----|------|
| D1 | Initial focus = Primary Play/Resume when playable and user has not moved |
| D2 | Down from action row reaches episodes (season control is a waypoint, not a wall) |
| D3 | Up from top episode row returns to action row |
| D4 | Episode left/right adjacent; stop at edges |
| D5 | Side-pane layouts: Right into pane, Left out |
| D6 | Related rails follow Home horizontal rules |
| D7 | Back → list + Home focus restore (S1) |
| D8 | Late metadata/recommendations never requestFocus |
| D9 | Primary enable: auto-focus once only if !userMoved |
| D10 | Skeleton same size as content |

Align with `detail_layouts_dpad_test` and `EpisodeFocusIntent`.

### Files (expected)

| Area | Paths |
|------|--------|
| Layouts | `lib/widgets/detail/detail_layout_*.dart` |
| Episodes | `lib/widgets/episodes_panel.dart` |
| Theme | `lib/widgets/detail/theme/*` |
| Screens | Showcase / merged series detail screens |
| Tests | extend `detail_layouts_dpad_test`; add initial-focus + async-no-steal |

### Shared bridge

Prefer one ActionRow ↔ Episodes focus bridge used by all layouts; layouts only supply visual slots.

### DetailFocusGate

Same pattern as Home: `userMoved`, `tryFocusPrimary`, async callbacks do not focus.

Android TV: keep progressive first paint (CTA early). tvOS: opening animation allowed; focus must land on Primary when finished if user has not moved.

---

## 7. S3 — Player

### Chrome states

`hidden → controls → subPanel` (subtitle | audio | quality)

### Back layers (mandatory)

1. subPanel open → close panel, focus trigger control  
2. controls visible → hide controls  
3. hidden → exit to Detail (Detail focuses Primary)

### Key map (summary)

| Input | hidden | controls | subPanel |
|-------|--------|----------|----------|
| OK / Select | play/pause + show | activate control | apply + close |
| Arrows | show controls | traverse / seek on progress | list move |
| Back / Menu | exit player | hide controls | close panel |
| Media play/pause | toggle | toggle | toggle |

### Structure

```
Transport: PlayPause | Rewind | Progress | Forward
Options:   Subtitle | Audio | Quality
Stack:     NextEpisode | Related?
```

### Files

- `lib/screens/video_player_screen.dart` and `video_player/widgets/*`
- Add/focus: `PlayerFocusController` + chrome enum
- Tests: `player_chrome_back_layers_test` (panel → chrome → exit)

### Auto-hide

~5s after last interaction while in `controls`; not while subPanel is open; reset on any key/seek.

---

## 8. S4 — Search

### Regions (top → bottom)

SearchField → Suggestions (history/hot) → Filter chips → Results → Keyboard (typing only)

### Default focus

1. First suggestion if any  
2. Else search field  
3. On return from Detail: previous result `itemId` if possible

### Hard rules

- Down from keyboard reaches results when results exist  
- Back dismisses keyboard before leaving Search  
- Suggestion OK fills query, searches, focuses first result  
- No trap between keyboard and results  

### Files

- `lib/screens/search_screen.dart` (search mode / board overlap — isolate focus groups)
- Suggestion/history widgets as present in tree
- Tests: `search_suggestion_focus_flow_test`

---

## 9. S5 — Design tokens

### Extension

`ThemeExtension<TvTheme>` with `space`, `type`, `focus`, `color`, `radius`.  
TV widgets read `context.tv` only — do not scale mobile text styles.

### Baseline tokens

**Space:** screenMarginX/Y 56/40, sectionGap 48, railGap 28, cardPadding 14, headerHeight 88, controlGap 24  

**Type roles:** display, h1, h2, h3, body, caption, meta, button  

**Focus:** scale 1.06, borderWidth 3, duration 140ms (Android TV), durationTvos 180ms, movingSimplify true on Android TV  

**Color roles:** surface, surfaceElevated, focus, onFocus, disabled, overlayScrim  

**Radius:** card, button, chip, control  

### Shared chrome helper

`tvFocusChrome(focused, child, {enableGlow})` — AnimatedScale + border; optional glow for collections without removing ring.

### Bind first

PosterCard, LandscapeCard, PrimaryButton, Player PlayPause — then rails, search chips, dialogs.

### Files

- `lib/.../tv_theme.dart` or extend existing TV style (`debrify_tv_style`)
- `test/tv_theme_focus_chrome_test.dart`
- Keep behavior of `collection_focus_*` goldens: glow optional, ring remains

---

## 10. End-to-end acceptance (remote only)

1. Cold start Home → focus predictable  
2. Horizontal to end of rail → no jump to next row  
3. OK → Detail → focus on Play  
4. OK → playback  
5. Arrows show controls; seek; open subtitles; Back closes panel only  
6. Back hides controls; Back exits to Detail on Play  
7. Back → Home on original card  
8. Search via suggestion → result → Detail → back to result  
9. Late Home rows / Detail recommendations never steal focus after user moved  
10. Empty/error states focus a recovery action  

Run on Android TV and tvOS.

---

## 11. Test gap matrix

| Existing | Keep | Add |
|----------|------|-----|
| `home_row_focus_test` | Yes | Cross-route restoration |
| `home_continuation_focus_test` | Yes | Wire with memory |
| `home_return_cache_test` | Yes | Clear focus store on invalidate |
| `detail_layouts_dpad_test` | Yes | Initial Play focus; async no-steal |
| `collection_focus_*` | Yes | Ring still present with glow |
| Player tests | Yes | Three-layer Back |
| Search/board tests | Yes | Suggestion-first; keyboard↔results |

New minimum:

- `home_focus_memory_test.dart`
- `home_focus_restoration_test.dart`
- `detail_initial_focus_and_async_test.dart`
- `player_chrome_back_layers_test.dart`
- `search_suggestion_focus_flow_test.dart`
- `tv_theme_focus_chrome_test.dart`

---

## 12. Cross-cutting checklist

- [ ] Stable ids for focus restore  
- [ ] User-moved gate on Home, Detail, Search  
- [ ] Async completion never steals focus  
- [ ] Layered Back everywhere (Search keyboard, Player panel, Dialogs)  
- [ ] Empty/Error/Offline: message + focusable recovery  
- [ ] TV theme extension registered on TV entrypoints  
- [ ] Focus decoration consistent; glow does not replace ring  
- [ ] Safe margins on all root TV scaffolds  

---

## 13. Implementation order (engineering)

```
S1a memory/gate → S1b save/restore → S1c async gate → S1d horizontal lock
    → S2 Detail focus contracts
    → S3 Player chrome
    → S4 Search flow
    → S5 token migration (shell can land earlier; widget bind after behavior)
```

S2 Back-to-Home restore depends on S1.  
S3 exit-to-Detail focus depends on S2 gate.  
S5 must not block S1–S2.

---

## 14. Risks

| Risk | Mitigation |
|------|------------|
| `search_screen.dart` size | Extract memory/restore; minimal hooks in screen |
| Multiple detail layouts diverge | Shared action↔episode bridge |
| Emulator ≠ device | One Android TV + one tvOS device per sprint exit |
| Focus animation cost | Android TV moving simplify; max two focus signals |
| Restore miss | Fallback to row first card / default entry; debug log |

---

## 15. Out of scope (this system doc)

- Rewriting collection glow/video feature set  
- Mobile/desktop navigation redesign  
- Addon/protocol changes (Bilibili remains via StremioService only)  

---

## 16. Document history

- 2026-10-09 — Initial TV Design System from full audit + S1–S5 specs, file checklists, acceptance and test gaps.
