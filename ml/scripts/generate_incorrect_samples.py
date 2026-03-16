"""
generate_incorrect_samples.py

Generate synthetic incorrect drawings for each of the 92 kana characters.
Output: ml/data/incorrect_samples/{hex_char}/{category}_{idx:04d}.png

Three categories:
  A. random     — random bezier strokes on a blank canvas
  B. confusable — font renders of visually similar characters
  C. partial    — correct character rendered with 1..(n-1) strokes only

Prerequisites:
  python extract_stroke_order.py    → ml/data/stroke_order.json
  python compute_confusion_matrix.py → ml/data/confusable_pairs.json
    (review + edit confusable_pairs.json before running this script)

Usage:
  python generate_incorrect_samples.py [--n-per-category 20] [--seed 42]
"""

import argparse
import json
import math
import random
import re
import sys
from pathlib import Path
from typing import Iterator

import numpy as np
from PIL import Image, ImageDraw

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))

from labels import LABELS, LABEL_TO_IDX
from render_fonts import bbox_normalize, remap_ink, char_to_hex

INK = 111
BG = 200
BG_WHITE = 255
IMG_SIZE = 64


# ---------------------------------------------------------------------------
# Font render loading (already in INK/BG colour space — do NOT remap)
# ---------------------------------------------------------------------------

def _load_font_renders(char: str) -> list[Path]:
    font_root = REPO_ROOT / "ml" / "data" / "font_renders"
    hex_c = char_to_hex(char)
    paths: list[Path] = []
    for font_dir in sorted(font_root.iterdir()):
        char_dir = font_dir / hex_c
        if char_dir.exists():
            paths.extend(sorted(char_dir.glob("*.png")))
    return paths


def _load_render_arr(path: Path) -> np.ndarray:
    """Load a font render PNG as-is (already in INK=111/BG=200 colour space)."""
    return np.array(Image.open(path).convert("L"), dtype=np.uint8)


# ---------------------------------------------------------------------------
# Category A: Random bezier strokes
# ---------------------------------------------------------------------------

def _bezier_pts(p0, p1, p2, p3, n: int = 30) -> list[tuple[float, float]]:
    pts = []
    for i in range(n):
        t = i / (n - 1)
        u = 1 - t
        x = u**3*p0[0] + 3*u**2*t*p1[0] + 3*u*t**2*p2[0] + t**3*p3[0]
        y = u**3*p0[1] + 3*u**2*t*p1[1] + 3*u*t**2*p2[1] + t**3*p3[1]
        pts.append((x, y))
    return pts


def generate_random_bezier(rng: random.Random) -> np.ndarray:
    """Random cubic bezier strokes, black-on-white → remapped to INK/BG."""
    img = Image.new("L", (IMG_SIZE, IMG_SIZE), color=BG_WHITE)
    draw = ImageDraw.Draw(img)
    n_strokes = rng.randint(1, 3)
    for _ in range(n_strokes):
        pts = [(rng.uniform(4, IMG_SIZE - 4), rng.uniform(4, IMG_SIZE - 4)) for _ in range(4)]
        curve = _bezier_pts(*pts, n=30)
        for i in range(len(curve) - 1):
            draw.line([curve[i], curve[i + 1]], fill=0, width=3)
    arr = np.array(img, dtype=np.uint8)
    arr = bbox_normalize(arr, BG_WHITE)
    arr = remap_ink(arr, INK, BG)
    return arr


# ---------------------------------------------------------------------------
# Category B: Confusable renders
# ---------------------------------------------------------------------------

def generate_confusable_samples(
    char: str,
    n: int,
    rng: random.Random,
    confusable_map: dict[str, list[str]],
) -> list[np.ndarray]:
    partners = [p for p in confusable_map.get(char, []) if p != char and p in LABEL_TO_IDX]
    if not partners:
        return []

    all_paths: list[Path] = []
    for p in partners:
        all_paths.extend(_load_font_renders(p))

    if not all_paths:
        return []

    rng.shuffle(all_paths)
    results = []
    for path in all_paths[:n]:
        # Font renders are already in INK/BG colour space — no remap needed.
        arr = _load_render_arr(path)
        results.append(arr)
    return results


# ---------------------------------------------------------------------------
# SVG path renderer (for partial stroke generation)
# ---------------------------------------------------------------------------

def _tokenize_svg(d: str) -> Iterator[str]:
    """Yield command letters and numeric strings from an SVG path string."""
    yield from re.findall(
        r"[MmLlCcQqZzAa]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?", d
    )


def _sample_svg_path(d: str, scale: float) -> list[tuple[float, float]]:
    """
    Parse an SVG path string (KanjiVG subset: M m C c Q q L l Z z)
    and return a dense point sequence scaled by `scale`.
    Handles implicit command repetition.
    """
    tokens = list(_tokenize_svg(d))
    pts: list[tuple[float, float]] = []
    pos = (0.0, 0.0)
    cmd = "M"
    i = 0

    def nums(count: int) -> list[float]:
        nonlocal i
        result = [float(tokens[i + k]) for k in range(count)]
        i += count
        return result

    def lerp_pts(start, end, n_steps: int) -> list[tuple[float, float]]:
        return [
            (start[0] + (j / n_steps) * (end[0] - start[0]),
             start[1] + (j / n_steps) * (end[1] - start[1]))
            for j in range(1, n_steps + 1)
        ]

    def cubic_pts(p0, p1, p2, p3) -> list[tuple[float, float]]:
        length_est = (
            math.hypot(p1[0]-p0[0], p1[1]-p0[1]) +
            math.hypot(p2[0]-p1[0], p2[1]-p1[1]) +
            math.hypot(p3[0]-p2[0], p3[1]-p2[1])
        )
        n = max(4, int(length_est / 2))
        result = []
        for j in range(1, n + 1):
            t = j / n; u = 1 - t
            result.append((
                u**3*p0[0] + 3*u**2*t*p1[0] + 3*u*t**2*p2[0] + t**3*p3[0],
                u**3*p0[1] + 3*u**2*t*p1[1] + 3*u*t**2*p2[1] + t**3*p3[1],
            ))
        return result

    def quad_pts(p0, p1, p2) -> list[tuple[float, float]]:
        length_est = (
            math.hypot(p1[0]-p0[0], p1[1]-p0[1]) +
            math.hypot(p2[0]-p1[0], p2[1]-p1[1])
        )
        n = max(4, int(length_est / 2))
        result = []
        for j in range(1, n + 1):
            t = j / n; u = 1 - t
            result.append((
                u**2*p0[0] + 2*u*t*p1[0] + t**2*p2[0],
                u**2*p0[1] + 2*u*t*p1[1] + t**2*p2[1],
            ))
        return result

    while i < len(tokens):
        tok = tokens[i]
        if tok.isalpha():
            cmd = tok
            i += 1
            if cmd in ("Z", "z"):
                continue
            continue  # fall through to param parsing on next iteration

        # Implicit repetition: reuse current cmd
        if cmd == "M":
            v = nums(2)
            pos = (v[0] * scale, v[1] * scale)
            pts.append(pos)
            cmd = "L"  # implicit lineto after first M coords
        elif cmd == "m":
            v = nums(2)
            pos = (pos[0] + v[0] * scale, pos[1] + v[1] * scale)
            pts.append(pos)
            cmd = "l"
        elif cmd == "L":
            v = nums(2)
            end = (v[0] * scale, v[1] * scale)
            n = max(1, int(math.hypot(end[0]-pos[0], end[1]-pos[1]) / 2))
            pts.extend(lerp_pts(pos, end, n))
            pos = end
        elif cmd == "l":
            v = nums(2)
            end = (pos[0] + v[0] * scale, pos[1] + v[1] * scale)
            n = max(1, int(math.hypot(end[0]-pos[0], end[1]-pos[1]) / 2))
            pts.extend(lerp_pts(pos, end, n))
            pos = end
        elif cmd == "C":
            v = nums(6)
            p1 = (v[0]*scale, v[1]*scale)
            p2 = (v[2]*scale, v[3]*scale)
            p3 = (v[4]*scale, v[5]*scale)
            pts.extend(cubic_pts(pos, p1, p2, p3))
            pos = p3
        elif cmd == "c":
            v = nums(6)
            p1 = (pos[0]+v[0]*scale, pos[1]+v[1]*scale)
            p2 = (pos[0]+v[2]*scale, pos[1]+v[3]*scale)
            p3 = (pos[0]+v[4]*scale, pos[1]+v[5]*scale)
            pts.extend(cubic_pts(pos, p1, p2, p3))
            pos = p3
        elif cmd == "Q":
            v = nums(4)
            p1 = (v[0]*scale, v[1]*scale)
            p2 = (v[2]*scale, v[3]*scale)
            pts.extend(quad_pts(pos, p1, p2))
            pos = p2
        elif cmd == "q":
            v = nums(4)
            p1 = (pos[0]+v[0]*scale, pos[1]+v[1]*scale)
            p2 = (pos[0]+v[2]*scale, pos[1]+v[3]*scale)
            pts.extend(quad_pts(pos, p1, p2))
            pos = p2
        else:
            # Unknown command / unsupported (S, s, A, a, etc.) — skip one token
            i += 1

    return pts


def render_stroke_subset(
    svg_paths: list[str],
    stroke_indices: list[int],
) -> np.ndarray:
    """
    Render selected strokes (by index into svg_paths) onto a 64×64 canvas.
    Returns a uint8 array in INK=111/BG=200 colour space.
    """
    scale = IMG_SIZE / 109.0
    img = Image.new("L", (IMG_SIZE, IMG_SIZE), color=BG)
    draw = ImageDraw.Draw(img)

    for idx in stroke_indices:
        pts = _sample_svg_path(svg_paths[idx], scale)
        for j in range(len(pts) - 1):
            draw.line([pts[j], pts[j + 1]], fill=INK, width=3)

    arr = np.array(img, dtype=np.uint8)
    # bbox_normalize uses ink < 128, which correctly identifies INK=111
    arr = bbox_normalize(arr, BG)
    return arr  # already in INK/BG — no remap needed


# ---------------------------------------------------------------------------
# Category C: Partial stroke renders (1 .. n-1 strokes)
# ---------------------------------------------------------------------------

def generate_partial_renders(
    char: str,
    n: int,
    rng: random.Random,
    stroke_order: dict[str, list[str]],
) -> list[np.ndarray]:
    """
    Render partial versions of `char` using 1..(n_strokes-1) strokes.
    Never includes the full set of strokes (those are correct, not incorrect).
    """
    paths = stroke_order.get(char)
    if not paths or len(paths) < 2:
        # Single-stroke character — can't make a partial that differs meaningfully
        return []

    n_strokes = len(paths)
    results = []
    attempts = 0

    while len(results) < n and attempts < n * 5:
        attempts += 1
        # Pick a random strict subset: 1 to n-1 strokes
        k = rng.randint(1, n_strokes - 1)
        # For variety: sometimes take the first k (natural partial), sometimes random subset
        if rng.random() < 0.5:
            indices = list(range(k))          # first k strokes
        else:
            indices = sorted(rng.sample(range(n_strokes), k))  # random k strokes

        arr = render_stroke_subset(paths, indices)
        # Skip if the render is blank (all background)
        if (arr < 128).sum() < 20:
            continue
        results.append(arr)

    return results


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Generate incorrect kana samples")
    parser.add_argument("--n-per-category", type=int, default=20)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument(
        "--confusable-pairs",
        type=str,
        default=str(REPO_ROOT / "ml" / "data" / "confusable_pairs.json"),
    )
    parser.add_argument(
        "--stroke-order",
        type=str,
        default=str(REPO_ROOT / "ml" / "data" / "stroke_order.json"),
    )
    args = parser.parse_args()

    rng = random.Random(args.seed)
    np.random.seed(args.seed)

    # Load confusable pairs (manually reviewed)
    confusable_path = Path(args.confusable_pairs)
    if not confusable_path.exists():
        print(f"ERROR: {confusable_path} not found.")
        print("Run compute_confusion_matrix.py first, then review the output.")
        sys.exit(1)
    with open(confusable_path, encoding="utf-8") as f:
        confusable_map: dict[str, list[str]] = json.load(f)
    print(f"Loaded confusable pairs from {confusable_path}")

    # Load stroke order data
    stroke_order_path = Path(args.stroke_order)
    if not stroke_order_path.exists():
        print(f"ERROR: {stroke_order_path} not found.")
        print("Run extract_stroke_order.py first.")
        sys.exit(1)
    with open(stroke_order_path, encoding="utf-8") as f:
        stroke_order: dict[str, list[str]] = json.load(f)
    print(f"Loaded stroke order for {len(stroke_order)} characters")

    out_root = REPO_ROOT / "ml" / "data" / "incorrect_samples"
    out_root.mkdir(parents=True, exist_ok=True)

    n = args.n_per_category
    counts = {"random": 0, "confusable": 0, "partial": 0}

    for char in LABELS:
        hex_c = char_to_hex(char)
        char_dir = out_root / hex_c
        char_dir.mkdir(parents=True, exist_ok=True)

        # --- A: Random bezier ---
        for idx in range(n):
            arr = generate_random_bezier(rng)
            Image.fromarray(arr).save(char_dir / f"random_{idx:04d}.png")
            counts["random"] += 1

        # --- B: Confusable renders ---
        for idx, arr in enumerate(generate_confusable_samples(char, n, rng, confusable_map)[:n]):
            Image.fromarray(arr).save(char_dir / f"confusable_{idx:04d}.png")
            counts["confusable"] += 1

        # --- C: Partial stroke renders ---
        for idx, arr in enumerate(generate_partial_renders(char, n, rng, stroke_order)[:n]):
            Image.fromarray(arr).save(char_dir / f"partial_{idx:04d}.png")
            counts["partial"] += 1

        print(f"  {char} ({hex_c}) done")

    print("\n=== Generation complete ===")
    for cat, cnt in counts.items():
        print(f"  {cat:12s}: {cnt:5d}")
    print(f"  {'TOTAL':12s}: {sum(counts.values()):5d}")


if __name__ == "__main__":
    main()
