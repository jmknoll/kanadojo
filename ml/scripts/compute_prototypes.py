"""
compute_prototypes.py

Compute per-character prototypes and radii from the trained KanaEmbedder.

For each of the 92 kana characters:
  1. Load all font render images (all fonts, all variants).
  2. Embed them through the model.
  3. Prototype = mean of embeddings, L2-normalized.
  4. Radius = 95th percentile L2 distance from prototype.

Output: KanaFlow/KanaFlow/Models/kana_prototypes.json

Usage:
  python compute_prototypes.py [--checkpoint ml/models/best_embedder.pt]
"""

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import torch
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))

from labels import LABELS, LABEL_TO_IDX
from augmentation import apply_val
from render_fonts import char_to_hex
from train_embedding import KanaEmbedder  # reuse architecture definition


# ---------------------------------------------------------------------------
# Device selection
# ---------------------------------------------------------------------------

def _device() -> torch.device:
    if torch.cuda.is_available():
        return torch.device("cuda")
    if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


# ---------------------------------------------------------------------------
# Load all font renders for a character
# ---------------------------------------------------------------------------

def _load_image_paths_for_char(char: str) -> list[Path]:
    font_root = REPO_ROOT / "ml" / "data" / "font_renders"
    hex_c = char_to_hex(char)
    paths: list[Path] = []
    for font_dir in sorted(font_root.iterdir()):
        char_dir = font_dir / hex_c
        if char_dir.exists():
            paths.extend(sorted(char_dir.glob("*.png")))
    return paths


# ---------------------------------------------------------------------------
# Embed a list of image paths in batches
# ---------------------------------------------------------------------------

@torch.no_grad()
def embed_images(
    paths: list[Path],
    model: KanaEmbedder,
    device: torch.device,
    batch_size: int = 64,
) -> np.ndarray:
    """Return (N, EMBED_DIM) float32 numpy array of L2-normalized embeddings."""
    all_embeddings: list[np.ndarray] = []

    for start in range(0, len(paths), batch_size):
        batch_paths = paths[start : start + batch_size]
        tensors: list[torch.Tensor] = []
        for p in batch_paths:
            arr = np.array(Image.open(p).convert("L"))
            t = apply_val(arr)
            tensors.append(t)

        batch = torch.stack(tensors, dim=0).to(device)  # (B, 1, H, W)
        embeddings = model(batch)  # already L2-normalized in forward()
        all_embeddings.append(embeddings.cpu().numpy())

    if not all_embeddings:
        return np.zeros((0, KanaEmbedder.EMBED_DIM), dtype=np.float32)

    return np.concatenate(all_embeddings, axis=0)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Compute kana embedding prototypes")
    parser.add_argument(
        "--checkpoint",
        type=str,
        default=str(REPO_ROOT / "ml" / "models" / "best_embedder.pt"),
    )
    args = parser.parse_args()

    checkpoint_path = Path(args.checkpoint)
    if not checkpoint_path.exists():
        print(f"ERROR: Checkpoint not found: {checkpoint_path}")
        print("Run train_embedding.py first.")
        sys.exit(1)

    device = _device()
    print(f"Device: {device}")
    print(f"Loading checkpoint: {checkpoint_path}")

    # Load model
    model = KanaEmbedder()
    state = torch.load(checkpoint_path, map_location=device)
    if isinstance(state, dict) and "model_state_dict" in state:
        model.load_state_dict(state["model_state_dict"])
        print(f"  Loaded from epoch {state.get('epoch', '?')} (val_loss={state.get('val_loss', '?'):.4f})")
    else:
        model.load_state_dict(state)
    model.to(device)
    model.eval()

    print(f"\nComputing prototypes for {len(LABELS)} characters...\n")

    prototypes: dict[str, dict] = {}
    radii: list[float] = []

    for char in LABELS:
        paths = _load_image_paths_for_char(char)
        if not paths:
            print(f"  WARNING: No font renders found for '{char}' — skipping.")
            continue

        embeddings = embed_images(paths, model, device)  # (N, 128)

        if embeddings.shape[0] == 0:
            print(f"  WARNING: Zero embeddings for '{char}' — skipping.")
            continue

        # Prototype: mean → L2-normalize
        mean_emb = embeddings.mean(axis=0)
        norm = np.linalg.norm(mean_emb)
        if norm < 1e-9:
            prototype = mean_emb
        else:
            prototype = mean_emb / norm

        # Radius: 95th percentile L2 distance from prototype
        diffs = embeddings - prototype[np.newaxis, :]
        distances = np.linalg.norm(diffs, axis=1)
        radius = float(np.percentile(distances, 95))

        prototypes[char] = {
            "prototype": prototype.tolist(),
            "radius": radius,
        }
        radii.append(radius)

        print(
            f"  {char}  n={len(paths):4d}  "
            f"radius={radius:.4f}  "
            f"mean_dist={distances.mean():.4f}  "
            f"max_dist={distances.max():.4f}"
        )

    # Save JSON
    out_path = REPO_ROOT / "KanaFlow" / "KanaFlow" / "Models" / "kana_prototypes.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(prototypes, f, ensure_ascii=False, indent=2)

    print(f"\nSaved prototypes → {out_path}")

    if radii:
        print(f"\n=== Radius summary across {len(radii)} characters ===")
        print(f"  min  : {min(radii):.4f}")
        print(f"  mean : {sum(radii)/len(radii):.4f}")
        print(f"  max  : {max(radii):.4f}")
        print(f"  std  : {float(np.std(radii)):.4f}")

        # Highlight outliers
        arr = np.array(radii)
        mean_r = arr.mean()
        std_r = arr.std()
        print("\nCharacters with unusually large radii (> mean + 1.5*std):")
        for char, r in zip(
            [c for c in LABELS if c in prototypes],
            [prototypes[c]["radius"] for c in LABELS if c in prototypes],
        ):
            if r > mean_r + 1.5 * std_r:
                print(f"  {char}  radius={r:.4f}")


if __name__ == "__main__":
    main()
