"""
dataset.py — PyTorch Dataset for the KanaFlow CNN classifier.

Loads font-rendered images from ml/data/font_renders/.
Run render_fonts.py first to generate them.

Labels come from labels.py LABELS list (92 classes, 0-indexed).

Usage:
    python scripts/download_fonts.py   # once
    python scripts/render_fonts.py     # once
    from dataset import build_datasets
    train_ds, val_ds, test_ds = build_datasets()
"""

from __future__ import annotations

import random
from pathlib import Path

import numpy as np
from PIL import Image
from torch.utils.data import Dataset

import sys
sys.path.insert(0, str(Path(__file__).parent))

from labels import LABELS, LABEL_TO_IDX
from augmentation import apply_train, apply_val

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT      = Path(__file__).resolve().parents[2]
FONT_RENDERS   = REPO_ROOT / "ml" / "data" / "font_renders"

# ---------------------------------------------------------------------------
# Image discovery
# ---------------------------------------------------------------------------

def _hex_to_char(hex_str: str) -> str | None:
    """Convert '0x3042' → 'あ', or '0x304d0x3083' → 'きゃ'."""
    try:
        parts = [p for p in hex_str.split("0x") if p]
        return "".join(chr(int(p, 16)) for p in parts)
    except (ValueError, OverflowError):
        return None


def _discover_sources() -> list[tuple[str, Path]]:
    """
    Walk all font subdirectories and return (label, image_path) pairs
    for every image that belongs to a known label.
    """
    if not FONT_RENDERS.exists():
        raise RuntimeError(
            f"Font renders not found: {FONT_RENDERS}\n"
            "Run:  python scripts/download_fonts.py\n"
            "      python scripts/render_fonts.py"
        )

    pairs: list[tuple[str, Path]] = []

    for font_dir in sorted(FONT_RENDERS.iterdir()):
        if not font_dir.is_dir() or font_dir.name.startswith("."):
            continue
        for char_dir in sorted(font_dir.iterdir()):
            if not char_dir.is_dir():
                continue
            char = _hex_to_char(char_dir.name)
            if char is None or char not in LABEL_TO_IDX:
                continue
            for png in sorted(char_dir.glob("*.png")):
                pairs.append((char, png))

    return pairs


# ---------------------------------------------------------------------------
# Dataset
# ---------------------------------------------------------------------------

class KanaDataset(Dataset):
    """PyTorch Dataset for kana character images."""

    def __init__(self, pairs: list[tuple[str, Path]], train: bool = True) -> None:
        self.pairs = pairs
        self.train = train

    def __len__(self) -> int:
        return len(self.pairs)

    def __getitem__(self, idx: int):
        label_char, img_path = self.pairs[idx]
        label_idx = LABEL_TO_IDX[label_char]

        arr = np.array(Image.open(img_path).convert("L"), dtype=np.uint8)

        if self.train:
            tensor = apply_train(arr)
        else:
            tensor = apply_val(arr)

        return tensor, label_idx


# ---------------------------------------------------------------------------
# Split builder
# ---------------------------------------------------------------------------

def build_datasets(
    val_fraction: float = 0.15,
    test_fraction: float = 0.15,
    seed: int = 42,
) -> tuple[KanaDataset, KanaDataset, KanaDataset]:
    """
    Discover all font-rendered images and split into train/val/test per class.

    With only ~10 fonts (~10 images per class), we use a higher val/test
    fraction so each split has at least one sample per class.

    Returns: (train_dataset, val_dataset, test_dataset)
    """
    pairs = _discover_sources()
    print(f"Total images found: {len(pairs)} across {len(set(p.parts[-3] for _, p in pairs))} fonts")

    # Group by label
    by_label: dict[str, list[Path]] = {label: [] for label in LABELS}
    for char, path in pairs:
        by_label[char].append(path)

    missing = [l for l, paths in by_label.items() if not paths]
    if missing:
        print(f"WARNING: {len(missing)} labels have no images: {missing[:10]}")

    rng = random.Random(seed)
    train_pairs: list[tuple[str, Path]] = []
    val_pairs:   list[tuple[str, Path]] = []
    test_pairs:  list[tuple[str, Path]] = []

    for label, paths in by_label.items():
        if not paths:
            continue
        shuffled = paths[:]
        rng.shuffle(shuffled)
        n = len(shuffled)
        n_test  = max(1, round(n * test_fraction))
        n_val   = max(1, round(n * val_fraction))
        n_train = n - n_val - n_test

        if n_train < 1:
            train_pairs.extend((label, p) for p in shuffled)
        else:
            train_pairs.extend((label, p) for p in shuffled[:n_train])
            val_pairs.extend(  (label, p) for p in shuffled[n_train:n_train + n_val])
            test_pairs.extend( (label, p) for p in shuffled[n_train + n_val:])

    print(
        f"Dataset split: {len(train_pairs)} train | "
        f"{len(val_pairs)} val | {len(test_pairs)} test"
    )

    return (
        KanaDataset(train_pairs, train=True),
        KanaDataset(val_pairs,   train=False),
        KanaDataset(test_pairs,  train=False),
    )


if __name__ == "__main__":
    train_ds, val_ds, test_ds = build_datasets()
    print(f"Sample: {train_ds[0][0].shape}, label={LABELS[train_ds[0][1]]}")
