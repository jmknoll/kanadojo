"""
render_fonts.py — Render all 92 main kana characters in each downloaded font,
generating multiple geometrically-distorted variants per character to simulate
the proportion and shape variation seen in real handwriting.

Output structure:
    ml/data/font_renders/<font_stem>/<hex_codepoint>/<variant>.png

Also writes ml/data/font_renders/sample_grid.png for visual inspection.

Distortions applied at render time (before bbox normalisation):
  - Independent x/y scaling (aspect ratio variation)
  - Shear along x and y axes

After distortion the character is bbox-normalised to 64×64 so it always
fills the frame — stretching then normalising changes the final proportions
in the same way a writer who draws tall/wide strokes would.

Usage:
    python scripts/render_fonts.py [--variants 20] [--size 256]
"""

from __future__ import annotations

import argparse
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from labels import LABELS

REPO_ROOT = Path(__file__).resolve().parents[2]
FONTS_DIR = REPO_ROOT / "ml" / "data" / "fonts"
OUT_BASE  = REPO_ROOT / "ml" / "data" / "font_renders"

TARGET_SIZE = 64
BBOX_FILL   = 0.80
INK_THRESH  = 128


def bbox_normalize(img: np.ndarray, bg: int) -> np.ndarray:
    """Crop to ink bounding box, scale to BBOX_FILL, centre on TARGET_SIZE canvas."""
    ink_mask = img < INK_THRESH
    rows = np.any(ink_mask, axis=1)
    cols = np.any(ink_mask, axis=0)

    if not rows.any():
        return np.full((TARGET_SIZE, TARGET_SIZE), bg, dtype=np.uint8)

    r0 = int(np.argmax(rows))
    r1 = int(len(rows) - 1 - np.argmax(rows[::-1]))
    c0 = int(np.argmax(cols))
    c1 = int(len(cols) - 1 - np.argmax(cols[::-1]))

    cropped = img[r0:r1 + 1, c0:c1 + 1]
    h, w = cropped.shape

    target_span = int(round(TARGET_SIZE * BBOX_FILL))
    scale = target_span / max(h, w)
    new_h = max(1, int(round(h * scale)))
    new_w = max(1, int(round(w * scale)))

    pil_crop = Image.fromarray(cropped).resize((new_w, new_h), Image.LANCZOS)
    scaled = np.array(pil_crop, dtype=np.uint8)

    canvas = np.full((TARGET_SIZE, TARGET_SIZE), bg, dtype=np.uint8)
    y0 = (TARGET_SIZE - new_h) // 2
    x0 = (TARGET_SIZE - new_w) // 2
    canvas[y0:y0 + new_h, x0:x0 + new_w] = scaled
    return canvas


def remap_ink(arr: np.ndarray, ink: int, bg: int) -> np.ndarray:
    """Remap black-on-white image to KanaRecognizer colour scheme."""
    arr_f = arr.astype(np.float32) / 255.0
    remapped = bg + (ink - bg) * (1.0 - arr_f)
    return np.clip(remapped, min(ink, bg), max(ink, bg)).astype(np.uint8)


def apply_distortion(img: Image.Image, rng: random.Random) -> Image.Image:
    """
    Apply a random affine distortion to a PIL image.

    Distortion parameters:
      x_scale: 0.65–1.35  — stretch/compress horizontally
      y_scale: 0.65–1.35  — stretch/compress vertically
      shear_x: -0.30–0.30 — slant along x axis
      shear_y: -0.20–0.20 — slant along y axis

    The affine matrix maps output pixel (x, y) to input pixel:
      src_x = x_scale * x + shear_x * y
      src_y = shear_y * x + y_scale * y
    centred on the image midpoint.
    """
    w, h = img.size
    cx, cy = w / 2, h / 2

    sx = rng.uniform(0.65, 1.35)
    sy = rng.uniform(0.65, 1.35)
    shx = rng.uniform(-0.30, 0.30)
    shy = rng.uniform(-0.20, 0.20)

    # PIL affine: (a, b, c, d, e, f) maps dst → src as:
    #   src_x = a*x + b*y + c
    #   src_y = d*x + e*y + f
    # We centre the transform on the image midpoint.
    a, b = sx,  shx
    d, e = shy, sy
    c = cx - a * cx - b * cy
    f = cy - d * cx - e * cy

    return img.transform(
        img.size,
        Image.AFFINE,
        (a, b, c, d, e, f),
        resample=Image.BILINEAR,
        fillcolor=255,
    )


def render_char(char: str, font: ImageFont.FreeTypeFont, size: int) -> Image.Image:
    """Render a character black-on-white at the given canvas size."""
    img = Image.new("L", (size, size), color=255)
    draw = ImageDraw.Draw(img)
    draw.text((size // 2, size // 2), char, font=font, fill=0, anchor="mm")
    return img


def char_to_hex(char: str) -> str:
    return "".join(f"0x{ord(c):04x}" for c in char)


def process_font(
    font_path: Path,
    render_size: int,
    n_variants: int,
    ink: int,
    bg: int,
    seed: int,
) -> dict[str, list[Path]]:
    """
    Render all LABELS for one font with n_variants distorted versions each.
    Variant 0 is always the undistorted canonical form.
    Returns {char: [out_path, ...]}.
    """
    font_stem = font_path.stem
    font = ImageFont.truetype(str(font_path), size=int(render_size * 0.80))
    rng = random.Random(seed)
    out: dict[str, list[Path]] = {}

    for char in LABELS:
        hex_name = char_to_hex(char)
        out_dir = OUT_BASE / font_stem / hex_name
        out_dir.mkdir(parents=True, exist_ok=True)
        paths: list[Path] = []

        base = render_char(char, font, render_size)

        for i in range(n_variants):
            if i == 0:
                rendered = base
            else:
                rendered = apply_distortion(base, rng)

            arr = np.array(rendered, dtype=np.uint8)
            normalised = bbox_normalize(arr, bg=255)
            remapped   = remap_ink(normalised, ink=ink, bg=bg)

            out_path = out_dir / f"{i:04d}.png"
            Image.fromarray(remapped).save(out_path)
            paths.append(out_path)

        out[char] = paths

    return out


def make_sample_grid(
    all_results: dict[str, dict[str, list[Path]]],
    n_chars: int = 8,
    n_variants_shown: int = 6,
):
    """
    Rows = sampled characters.
    Columns = evenly-spaced variants from one font, to show distortion range.
    """
    if not all_results:
        return

    # Pick the first font to show variants from
    font_name = next(iter(all_results))
    chars = random.sample(LABELS, min(n_chars, len(LABELS)))

    cell  = TARGET_SIZE
    pad   = 4
    label_w = 20
    grid_w = label_w + n_variants_shown * (cell + pad) + pad
    grid_h = len(chars) * (cell + pad) + pad

    grid = Image.new("L", (grid_w, grid_h), color=240)
    draw = ImageDraw.Draw(grid)

    for row, char in enumerate(chars):
        y = pad + row * (cell + pad)
        draw.text((2, y + cell // 2), char, fill=0)
        paths = all_results[font_name].get(char, [])
        # Sample evenly across the variants
        indices = np.linspace(0, len(paths) - 1, n_variants_shown, dtype=int)
        for col, idx in enumerate(indices):
            x = label_w + pad + col * (cell + pad)
            img_path = paths[idx]
            if img_path.exists():
                grid.paste(Image.open(img_path).convert("L"), (x, y))

    out_path = OUT_BASE / "sample_grid.png"
    grid.save(out_path)
    print(f"Sample grid → {out_path}  (font: {font_name}, {n_variants_shown} variants shown)")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--variants", type=int, default=20,
                        help="Distorted variants per character per font (default 20)")
    parser.add_argument("--size", type=int, default=256,
                        help="Intermediate render size in pixels (default 256)")
    parser.add_argument("--ink", type=int, default=111,
                        help="Ink pixel value 0-255 (default 111)")
    parser.add_argument("--bg",  type=int, default=200,
                        help="Background pixel value 0-255 (default 200)")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    font_files = sorted(FONTS_DIR.glob("*.ttf")) + sorted(FONTS_DIR.glob("*.otf"))
    if not font_files:
        print(f"No fonts found in {FONTS_DIR}. Run download_fonts.py first.")
        sys.exit(1)

    approx_total = len(font_files) * len(LABELS) * args.variants
    print(f"Fonts:      {len(font_files)}")
    print(f"Characters: {len(LABELS)}")
    print(f"Variants:   {args.variants} per character per font")
    print(f"Approx total images: {approx_total}\n")

    OUT_BASE.mkdir(parents=True, exist_ok=True)
    all_results: dict[str, dict[str, list[Path]]] = {}

    for i, font_path in enumerate(font_files):
        print(f"  [{i+1}/{len(font_files)}] {font_path.name} ...", end=" ", flush=True)
        try:
            result = process_font(
                font_path, args.size, args.variants,
                args.ink, args.bg, args.seed + i,
            )
            all_results[font_path.stem] = result
            total = sum(len(v) for v in result.values())
            print(f"{total} images")
        except Exception as e:
            print(f"ERROR: {e}")

    grand_total = sum(
        len(paths)
        for char_dict in all_results.values()
        for paths in char_dict.values()
    )
    print(f"\nTotal images saved: {grand_total}")

    if all_results:
        make_sample_grid(all_results)


if __name__ == "__main__":
    main()
