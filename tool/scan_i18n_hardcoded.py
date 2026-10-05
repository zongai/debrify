#!/usr/bin/env python3
"""Scan Debrify Dart sources for likely user-visible hardcoded English strings.

P0 i18n inventory helper. Prioritizes recall for Text/title/label/SnackBar-style
UI copy so translators can batch work.

Usage:
  python3 tool/scan_i18n_hardcoded.py
  python3 tool/scan_i18n_hardcoded.py --out docs/i18n-untranslated-inventory.md
  python3 tool/scan_i18n_hardcoded.py --module player
  python3 tool/scan_i18n_hardcoded.py --json /tmp/i18n.json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

SKIP_PARTS = {"deprecated", ".dart_tool", "generated"}
SKIP_FILE_NAMES = {"diagnostic_log.dart"}

MODULE_RULES: list[tuple[str, re.Pattern[str]]] = [
    ("nav_shell", re.compile(r"lib/main\.dart$|lib/widgets/.*nav|sidebar|rail", re.I)),
    ("settings", re.compile(r"lib/screens/settings|/settings_screen\.dart|settings/widgets", re.I)),
    ("home_discover", re.compile(r"search_screen\.dart|discover|home_", re.I)),
    ("detail", re.compile(r"catalog_item_detail|detail_screen|episodes_screen", re.I)),
    ("player", re.compile(r"video_player|player/", re.I)),
    ("iptv", re.compile(r"iptv|epg", re.I)),
    ("downloads_cloud", re.compile(r"download|real_debrid|torbox|premiumize|alldebrid|pikpak|webdav|cloud", re.I)),
    ("addons_engines", re.compile(r"addon|stremio|engine|indexer|torrent_service", re.I)),
    ("tracking", re.compile(r"trakt|simkl|mdblist|tracking", re.I)),
    ("profiles", re.compile(r"profile", re.I)),
    ("l10n", re.compile(r"lib/l10n/", re.I)),
    ("other", re.compile(r".")),
]

RE_EXCLUDE = re.compile(
    r"^(https?://|package:|assets/|lib/|application/|text/|X-Plex-|"
    r"[A-Z][A-Z0-9_]{2,}$|"  # CONST
    r"[a-z]+(?:[A-Z][a-z0-9]+)+$|"  # camelCase alone
    r"[a-z0-9_\-\.]+$|"  # slug
    r"\d)"
)
RE_HAS_LETTER = re.compile(r"[A-Za-z]")
RE_HAS_CJK = re.compile(r"[\u4e00-\u9fff]")
RE_CODEY = re.compile(r"[\{\}\<\>\$\\]|://")


def load_known_phrases(l10n_path: Path) -> set[str]:
    known: set[str] = set()
    if not l10n_path.is_file():
        return known
    text = l10n_path.read_text(encoding="utf-8", errors="replace")
    for m in re.finditer(r"'((?:\\'|[^']){2,160})'\s*:\s*'", text):
        known.add(m.group(1).replace("\\'", "'"))
    return known


def module_for(path: str) -> str:
    rel = path.replace("\\", "/")
    for name, pat in MODULE_RULES:
        if pat.search(rel):
            return name
    return "other"


def should_skip(path: Path) -> bool:
    if path.suffix != ".dart":
        return True
    if set(path.parts) & SKIP_PARTS:
        return True
    if path.name in SKIP_FILE_NAMES:
        return True
    return False


def is_candidate(s: str) -> bool:
    s = s.strip()
    if len(s) < 2 or len(s) > 160:
        return False
    if not RE_HAS_LETTER.search(s):
        return False
    if RE_HAS_CJK.search(s):
        return False
    if RE_CODEY.search(s):
        return False
    if RE_EXCLUDE.match(s):
        return False
    if re.fullmatch(r"[A-Za-z]{1,2}", s):
        return False
    return True


def _line_number(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def scan_file(path: Path) -> list[tuple[int, str, str]]:
    try:
        raw = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []

    # Blank out full-line comments
    cleaned_lines = []
    for line in raw.splitlines():
        st = line.lstrip()
        if st.startswith("//") or st.startswith("///") or st.startswith("*"):
            cleaned_lines.append("")
        elif st.startswith("import ") or st.startswith("export "):
            cleaned_lines.append("")
        else:
            cleaned_lines.append(line)
    text = "\n".join(cleaned_lines)

    patterns: list[tuple[str, re.Pattern[str]]] = [
        ("text", re.compile(r"""(?:const\s+)?Text\s*\(\s*['"]([^'"]{2,160})['"]""")),
        ("text_ml", re.compile(r"""(?:const\s+)?Text\s*\(\s*\n\s*['"]([^'"]{2,160})['"]""")),
        ("selectable", re.compile(r"""SelectableText\s*\(\s*['"]([^'"]{2,160})['"]""")),
        (
            "field",
            re.compile(
                r"(?:title|subtitle|label|labelText|hintText|helperText|tooltip|"
                r"semanticsLabel|semanticLabel|message|content|blurb|description|"
                r"eyebrow|heading|buttonLabel|emptyMessage|errorMessage)\s*:\s*"
                r"""['"]([^'"]{2,160})['"]"""
            ),
        ),
        ("snackbar", re.compile(r"""SnackBar\s*\(\s*content:\s*Text\s*\(\s*['"]([^'"]{2,160})['"]""")),
        ("dialog_title", re.compile(r"""title:\s*Text\s*\(\s*['"]([^'"]{2,160})['"]""")),
    ]

    found: list[tuple[int, str, str]] = []
    seen: set[tuple[int, str]] = set()
    for kind, rx in patterns:
        for m in rx.finditer(text):
            s = m.group(1)
            if not is_candidate(s):
                continue
            line = _line_number(text, m.start())
            key = (line, s)
            if key in seen:
                continue
            seen.add(key)
            found.append((line, kind, s))
    return found


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, default=ROOT / "docs" / "i18n-untranslated-inventory.md")
    ap.add_argument("--json", type=Path, default=None)
    ap.add_argument("--module", action="append", default=[])
    ap.add_argument("--root", type=Path, default=LIB)
    args = ap.parse_args()
    filter_modules = set(args.module)

    known = load_known_phrases(ROOT / "lib" / "l10n" / "app_localizations.dart")
    by_module: dict[str, list[dict]] = defaultdict(list)
    phrase_locations: dict[str, list[str]] = defaultdict(list)
    known_locations: dict[str, list[str]] = defaultdict(list)

    for path in sorted(args.root.rglob("*.dart")):
        if should_skip(path):
            continue
        rel = path.relative_to(ROOT).as_posix()
        mod = module_for(rel)
        if filter_modules and mod not in filter_modules:
            continue
        for line, kind, s in scan_file(path):
            status = "in_phrase_table" if s in known else "needs_translation"
            item = {
                "string": s,
                "file": rel,
                "line": line,
                "kind": kind,
                "module": mod,
                "status": status,
            }
            by_module[mod].append(item)
            loc = f"{rel}:{line}"
            if status == "needs_translation":
                phrase_locations[s].append(loc)
            else:
                known_locations[s].append(loc)

    order = [
        "nav_shell", "settings", "home_discover", "detail", "player", "iptv",
        "downloads_cloud", "addons_engines", "tracking", "profiles", "l10n", "other",
    ]
    modules_sorted = [m for m in order if m in by_module] + [
        m for m in sorted(by_module) if m not in order
    ]

    total = sum(len(v) for v in by_module.values())
    needs = sum(1 for v in by_module.values() for x in v if x["status"] == "needs_translation")
    known_hit = total - needs
    unique_needs = len(phrase_locations)

    out: list[str] = []
    out.append("# i18n untranslated inventory (P0 scan)")
    out.append("")
    out.append("Generated by `python3 tool/scan_i18n_hardcoded.py`.")
    out.append("")
    out.append("## Summary")
    out.append("")
    out.append("| Metric | Count |")
    out.append("|--------|------:|")
    out.append(f"| Occurrences matched | {total} |")
    out.append(f"| Already in phrase/key tables | {known_hit} |")
    out.append(f"| Needs translation (occurrences) | {needs} |")
    out.append(f"| Needs translation (unique strings) | {unique_needs} |")
    out.append(f"| In table but still at call sites (unique) | {len(known_locations)} |")
    out.append("")
    out.append("### By module")
    out.append("")
    out.append("| Module | Occurrences | Needs translation | In table (wire `t()` if needed) |")
    out.append("|--------|------------:|------------------:|--------------------------------:|")
    for mod in modules_sorted:
        items = by_module[mod]
        n = sum(1 for x in items if x["status"] == "needs_translation")
        k = len(items) - n
        out.append(f"| `{mod}` | {len(items)} | {n} | {k} |")
    out.append("")
    out.append(
        "- **needs_translation**: English UI string not yet in `app_localizations.dart`.\n"
        "- **in_phrase_table**: string exists in the locale maps; call site may still "
        "need `AppLocalizations.of(context).t('...')` or a named getter."
    )
    out.append("")
    out.append("## Recommended batch order (plan)")
    out.append("")
    out.append("1. `nav_shell` + `settings`")
    out.append("2. `home_discover` + `detail`")
    out.append("3. `player` + `iptv`")
    out.append("4. `downloads_cloud` + `addons_engines`")
    out.append("5. `tracking` + `profiles` + `other`")
    out.append("")
    out.append("## Unique strings needing translation")
    out.append("")
    ranked = sorted(phrase_locations.items(), key=lambda kv: (-len(kv[1]), kv[0].lower()))
    for s, locs in ranked:
        out.append(f"### `{s}`")
        out.append("")
        out.append(f"- Occurrences: {len(locs)}")
        for loc in locs[:8]:
            out.append(f"- `{loc}`")
        if len(locs) > 8:
            out.append(f"- … +{len(locs) - 8} more")
        out.append("")

    out.append("## Per-module detail (needs translation only)")
    out.append("")
    for mod in modules_sorted:
        items = [x for x in by_module[mod] if x["status"] == "needs_translation"]
        if not items:
            continue
        out.append(f"### Module `{mod}` ({len(items)} occurrences)")
        out.append("")
        seen: set[str] = set()
        for x in sorted(items, key=lambda z: (z["file"], z["line"])):
            if x["string"] in seen:
                continue
            seen.add(x["string"])
            out.append(f"- `{x['string']}` — `{x['file']}:{x['line']}`")
        out.append("")

    out.append("## In phrase table (verify call sites)")
    out.append("")
    out.append(
        "These English strings already have translations. Prefer wiring "
        "`l10n.t('...')` at remaining hardcoded call sites."
    )
    out.append("")
    for s, locs in sorted(known_locations.items(), key=lambda kv: (-len(kv[1]), kv[0].lower())):
        out.append(f"- `{s}` ({len(locs)}×) e.g. `{locs[0]}`")
    out.append("")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"Wrote {args.out}")
    print(f"  unique needs translation: {unique_needs}")
    print(f"  occurrences needs: {needs} / total {total}")

    if args.json:
        payload = {
            "total_occurrences": total,
            "needs_occurrences": needs,
            "unique_needs": unique_needs,
            "by_module": {m: by_module[m] for m in modules_sorted},
            "unique": [{"string": s, "locations": locs} for s, locs in ranked],
        }
        args.json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Wrote {args.json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
