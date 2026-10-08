# S2–S5 File Checklists

Companion to `docs/tv-design-system.md`. Use with full Debrify `lib/` checkout.

---

## S2 Detail

### Goals

- Default focus = Primary Play
- Action row ↓ → episodes (season not a wall)
- Async metadata never steals focus
- Back triggers Home restore (S1)

### Files to inspect / touch

| Path | Checklist |
|------|-----------|
| `lib/widgets/detail/detail_layout_console.dart` | D1–D5, D8–D10 |
| `lib/widgets/detail/detail_layout_dossier.dart` | same |
| `lib/widgets/detail/detail_layout_marquee.dart` | same |
| `lib/widgets/detail/detail_layout_premium.dart` | same |
| `lib/widgets/detail/detail_layout_stage.dart` | same |
| Other `detail_layout_*` if present | same |
| `lib/widgets/episodes_panel.dart` | Landing episode focus; season waypoint |
| `lib/widgets/detail/detail_model.dart` | Focus intent fields if any |
| Showcase / merged series screens | Opening gate vs early CTA; DetailFocusGate |
| `test/detail_layouts_dpad_test.dart` | Extend |
| `test/detail_initial_focus_and_async_test.dart` | **Add** |

### Implementation notes

- Introduce shared `DetailFocusGate` (userMoved / tryFocusPrimary)
- One ActionRow ↔ Episodes key bridge for all layouts
- Recommendations/cast callbacks: setState only
- Primary `onEnabled`: tryFocusPrimary once if !userMoved

### Exit

All enabled layouts: enter → OK plays without Down; Up/Down episode bridge; async no steal; Back to Home card (with S1).

---

## S3 Player

### Goals

- Chrome: hidden | controls | subPanel
- Back: panel → hide chrome → exit Detail
- Progress seek on focus; subtitle/audio/quality panels

### Files

| Path | Checklist |
|------|-----------|
| `lib/screens/video_player_screen.dart` | Root key handling; chrome state |
| `lib/…/video_player/widgets/*` | Transport, options, panels |
| Player style prefs tests | Do not regress |
| `test/player_chrome_back_layers_test.dart` | **Add** |

### Implementation notes

- `PlayerFocusController` + enum chrome
- FocusScope around controls; subPanel exclusive focus ring
- Auto-hide timer ~5s; disabled while panel open
- exitToDetail → Detail tryFocusPrimary

### Exit

Remote-only: pause, seek, subtitles, next episode, three-layer Back to Detail on Play.

---

## S4 Search

### Goals

- Suggestions before keyboard
- Keyboard ↔ results no trap
- Back dismisses keyboard first
- Restore result item from Detail

### Files

| Path | Checklist |
|------|-----------|
| `lib/screens/search_screen.dart` | Search phase focus groups (isolate from Home board where possible) |
| Suggestion / history widgets | First suggestion default focus |
| Keyboard host | Down to first result |
| `test/search_suggestion_focus_flow_test.dart` | **Add** |

### Exit

Complete search using only a suggestion; keyboard Down reaches results; Detail Back restores result focus.

---

## S5 Tokens

### Goals

- `TvTheme` extension; TV widgets use `context.tv`
- Shared `tvFocusChrome`; glow does not remove ring

### Files

| Path | Checklist |
|------|-----------|
| TV theme / `debrify_tv_style` module | Extension + defaults |
| Poster / landscape / primary button widgets | Bind tokens |
| Player controls | controlGap, focus chrome |
| Collection card | glow optional + ring |
| `test/tv_theme_focus_chrome_test.dart` | **Add** |
| `test/collection_focus_visual_test.dart` | Still green |

### Exit

No TV primary path using raw mobile text sizes; consistent focus chrome on main cards/buttons.

---

## Device QA (every sprint exit)

- [ ] Android TV physical remote: main path steps 1–10 in `tv-design-system.md` §10
- [ ] tvOS Siri Remote: same path, Menu = Back layers
- [ ] Weak network: empty/error focusable recovery
