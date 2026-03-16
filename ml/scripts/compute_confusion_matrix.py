"""
compute_confusion_matrix.py

Run all font renders through the trained KanaClassifier and rank confusable
partners per character by their mean softmax probability.

Using mean softmax (rather than argmax mis-predictions) gives a meaningful
signal even when the model is highly accurate on clean font renders: the
runner-up probabilities reveal which characters the model finds most similar.

Confusable candidates are restricted to the same script as the target:
  - Hiragana (LABELS indices 0–45) → only other hiragana
  - Katakana (LABELS indices 46–91) → only other katakana

Output:
  ml/data/confusable_pairs.json  — { "あ": ["か", "お", ...], ... }

Usage:
  python compute_confusion_matrix.py [--top 4] [--checkpoint ml/models/best_model.pt]
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
from model import build_model

# First 46 labels are hiragana, next 46 are katakana (see labels.py)
HIRAGANA_INDICES = set(range(46))
KATAKANA_INDICES = set(range(46, 92))


def _device() -> torch.device:
    if torch.cuda.is_available():
        return torch.device("cuda")
    if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def _same_script_indices(char_idx: int) -> set[int]:
    return HIRAGANA_INDICES if char_idx in HIRAGANA_INDICES else KATAKANA_INDICES


@torch.no_grad()
def compute_mean_probs(
    model: torch.nn.Module,
    device: torch.device,
    font_root: Path,
    max_per_char: int = 60,
) -> np.ndarray:
    """
    For each character, average the softmax output over up to `max_per_char`
    font renders.  Returns an (N, N) array where row i is the mean softmax
    probability distribution for class i.
    """
    n = len(LABELS)
    mean_probs = np.zeros((n, n), dtype=np.float32)

    model.eval()
    for char in LABELS:
        idx = LABEL_TO_IDX[char]
        hex_c = char_to_hex(char)
        paths: list[Path] = []
        for font_dir in sorted(font_root.iterdir()):
            char_dir = font_dir / hex_c
            if char_dir.exists():
                paths.extend(sorted(char_dir.glob("*.png")))
            if len(paths) >= max_per_char:
                break
        paths = paths[:max_per_char]

        if not paths:
            print(f"  WARNING: no renders for '{char}'")
            continue

        tensors = []
        for p in paths:
            arr = np.array(Image.open(p).convert("L"))
            tensors.append(apply_val(arr))  # already a (1,64,64) tensor

        batch = torch.stack(tensors, dim=0).to(device)  # (B, 1, 64, 64)
        probs = torch.softmax(model(batch), dim=1).cpu().numpy()  # (B, 92)
        mean_probs[idx] = probs.mean(axis=0)

    return mean_probs


def main() -> None:
    parser = argparse.ArgumentParser(description="Build kana confusable pairs from softmax probs")
    parser.add_argument(
        "--checkpoint",
        type=str,
        default=str(REPO_ROOT / "ml" / "models" / "best_model.pt"),
    )
    parser.add_argument("--top", type=int, default=4, help="Confusable partners per character")
    parser.add_argument("--max-per-char", type=int, default=60)
    args = parser.parse_args()

    checkpoint_path = Path(args.checkpoint)
    if not checkpoint_path.exists():
        print(f"ERROR: {checkpoint_path} not found")
        sys.exit(1)

    device = _device()
    print(f"Device: {device}")
    print(f"Loading checkpoint: {checkpoint_path}")

    model = build_model()
    state = torch.load(checkpoint_path, map_location=device)
    if isinstance(state, dict):
        weights = state.get("model_state_dict") or state.get("model_state") or state
    else:
        weights = state
    model.load_state_dict(weights)
    model.to(device)
    model.eval()

    font_root = REPO_ROOT / "ml" / "data" / "font_renders"
    print(f"\nRunning inference on font renders (max {args.max_per_char} per char)...")
    mean_probs = compute_mean_probs(model, device, font_root, args.max_per_char)

    confusable_pairs: dict[str, list[str]] = {}
    print(f"\n=== Top-{args.top} confusable partners (mean softmax, same script only) ===")

    for i, char in enumerate(LABELS):
        row = mean_probs[i].copy()
        row[i] = 0.0  # exclude self

        # Zero out the other script so we only compare within the same script
        other_script = KATAKANA_INDICES if i in HIRAGANA_INDICES else HIRAGANA_INDICES
        for j in other_script:
            row[j] = 0.0

        top_indices = np.argsort(row)[::-1][: args.top]
        partners = [LABELS[j] for j in top_indices if row[j] > 0]
        confusable_pairs[char] = partners

        partner_strs = ", ".join(
            f"'{p}' ({mean_probs[i, LABEL_TO_IDX[p]]:.4f})" for p in partners
        )
        print(f"  '{char}' → {partner_strs or '(none)'}")

    out_path = REPO_ROOT / "ml" / "data" / "confusable_pairs.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(confusable_pairs, f, ensure_ascii=False, indent=2)

    print(f"\nSaved → {out_path}")
    print("Review and edit this file before running generate_incorrect_samples.py")


if __name__ == "__main__":
    main()
