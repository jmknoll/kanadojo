"""
extract_stroke_order.py

Parse stroke SVG paths out of KanaFlow/KanaFlow/Models/StrokeOrder.swift
and write them to ml/data/stroke_order.json for use by the Python pipeline.

Output format:
  { "あ": ["M31.01,33c...", "M49.76,...", ...], ... }

Usage:
  python extract_stroke_order.py
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SWIFT_FILE = REPO_ROOT / "KanaFlow" / "Models" / "StrokeOrder.swift"
OUT_FILE = REPO_ROOT / "ml" / "data" / "stroke_order.json"


def extract(swift_text: str) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    current_char: str | None = None
    current_paths: list[str] = []

    for raw_line in swift_text.splitlines():
        line = raw_line.strip()

        # Entire entry on one line:  "X": ["path1", "path2"],
        m = re.match(r'^"([^"]+)":\s*\[(.+)\],?$', line)
        if m and "M" in m.group(2):
            if current_char and current_paths:
                result[current_char] = current_paths
                current_char = None
                current_paths = []
            char_key = m.group(1)
            paths_raw = m.group(2)
            paths_found = re.findall(r'"(M[^"]+)"', paths_raw)
            if paths_found:
                result[char_key] = paths_found
            continue

        # Character key line (opening bracket on its own):  "X": [
        m = re.match(r'^"([^"]+)":\s*\[$', line)
        if m:
            if current_char and current_paths:
                result[current_char] = current_paths
            current_char = m.group(1)
            current_paths = []
            continue

        # SVG path line (middle or last without inline bracket):  "Mxx,yy..."  or  "Mxx,yy...",
        m = re.match(r'^"(M[^"]+)",?$', line)
        if m and current_char is not None:
            current_paths.append(m.group(1))
            continue

        # SVG path line that also closes the array: "Mxx..."],
        m = re.match(r'^"(M[^"]+)"\]', line)
        if m and current_char is not None:
            current_paths.append(m.group(1))
            result[current_char] = current_paths
            current_char = None
            current_paths = []
            continue

        # Standalone closing bracket
        if line in ("],", "]") and current_char is not None:
            result[current_char] = current_paths
            current_char = None
            current_paths = []

    return result


def main() -> None:
    if not SWIFT_FILE.exists():
        print(f"ERROR: {SWIFT_FILE} not found")
        sys.exit(1)

    text = SWIFT_FILE.read_text(encoding="utf-8")
    data = extract(text)

    if not data:
        print("ERROR: No stroke data found — check Swift file format")
        sys.exit(1)

    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    stroke_counts = {k: len(v) for k, v in data.items()}
    print(f"Extracted {len(data)} characters → {OUT_FILE}")
    print(f"Stroke counts: min={min(stroke_counts.values())} max={max(stroke_counts.values())}")

    # Show any characters with unexpected stroke counts (sanity check)
    for char, paths in sorted(data.items(), key=lambda x: -len(x[1])):
        if len(paths) > 6:
            print(f"  NOTE: '{char}' has {len(paths)} strokes")


if __name__ == "__main__":
    main()
