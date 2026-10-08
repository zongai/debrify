#!/usr/bin/env bash
# Package TV Design System deliverables for merge into a full Debrify checkout.
# Usage (from debrify-main or artifacts root):
#   bash docs/tv-design-system/pack-tv-modules.sh [output.tgz]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:-$ROOT/tv-design-system-bundle.tgz}"
cd "$ROOT"
FILES=(
  docs/tv-design-system.md
  docs/tv-design-system/FULL_REPO_MERGE_GUIDE.md
  docs/tv-design-system/IMPLEMENTATION_PROGRESS.md
  docs/tv-design-system/S1B_SEARCH_SCREEN_HOOKS.md
  docs/tv-design-system/UPSTREAM_COMPATIBILITY.md
  docs/tv-design-system/s1b_search_screen.patch
  docs/tv-design-system/s2-s5-file-checklists.md
  lib/services/home_focus_memory.dart
  lib/widgets/home/home_focus_restore.dart
  lib/widgets/home/home_focus_board_bridge.dart
  lib/widgets/home/rail_locked_traversal.dart
  lib/widgets/detail/detail_focus_gate.dart
  lib/widgets/player/player_focus_controller.dart
  lib/widgets/search/search_focus_controller.dart
  lib/theme/tv_theme.dart
  lib/screens/search_screen.dart
  lib/screens/search/search_stage_widgets.dart
  test/home_focus_memory_test.dart
  test/home_focus_restoration_test.dart
  test/home_focus_board_bridge_test.dart
  test/rail_locked_traversal_test.dart
  test/detail_focus_gate_test.dart
  test/player_focus_controller_test.dart
  test/search_focus_controller_test.dart
  test/tv_theme_test.dart
)
# Optional: only include if present (upstream copies)
for opt in \
  lib/widgets/home/home_row_focus.dart \
  lib/widgets/home/home_continuation_focus.dart \
  lib/theme/app_focus.dart
do
  [[ -f "$opt" ]] && FILES+=("$opt")
done
tar -czf "$OUT" "${FILES[@]}"
echo "Wrote $OUT"
tar -tzf "$OUT" | wc -l
