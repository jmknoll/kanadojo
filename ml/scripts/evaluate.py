"""
evaluate.py — Evaluate a trained KanaFlow model on the test split.

Usage:
    python evaluate.py [--checkpoint ml/models/best_model.pt]

Outputs:
    Top-1 accuracy (overall + per-class breakdown)
    Confusion matrix saved to ml/models/confusion_matrix.png
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import torch
from torch.utils.data import DataLoader

REPO_ROOT = Path(__file__).resolve().parents[2]

import sys
sys.path.insert(0, str(Path(__file__).parent))

from dataset import build_datasets
from model import build_model
from labels import LABELS


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument(
        "--checkpoint",
        default=str(REPO_ROOT / "ml" / "models" / "best_model.pt"),
    )
    p.add_argument("--batch-size", type=int, default=64)
    p.add_argument("--workers",    type=int, default=4)
    return p.parse_args()


def _device() -> torch.device:
    if torch.cuda.is_available():
        return torch.device("cuda")
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def evaluate(args: argparse.Namespace) -> None:
    device = _device()

    _, _, test_ds = build_datasets()
    test_loader = DataLoader(
        test_ds, batch_size=args.batch_size, shuffle=False, num_workers=args.workers
    )

    model = build_model().to(device)
    ckpt = torch.load(args.checkpoint, map_location=device, weights_only=True)
    model.load_state_dict(ckpt["model_state"])
    model.eval()
    print(f"Loaded checkpoint from epoch {ckpt.get('epoch', '?')}")

    num_classes = len(LABELS)
    confusion = np.zeros((num_classes, num_classes), dtype=np.int32)
    all_preds: list[int] = []
    all_targets: list[int] = []

    with torch.no_grad():
        for batch_x, batch_y in test_loader:
            batch_x = batch_x.to(device)
            logits = model(batch_x)
            preds = logits.argmax(dim=1).cpu().numpy()
            targets = batch_y.numpy()
            for p, t in zip(preds, targets):
                confusion[t, p] += 1
            all_preds.extend(preds.tolist())
            all_targets.extend(targets.tolist())

    # Overall accuracy
    correct = sum(p == t for p, t in zip(all_preds, all_targets))
    total = len(all_targets)
    top1 = correct / total if total > 0 else 0.0
    print(f"\nTop-1 accuracy: {top1:.4f} ({correct}/{total})")

    # Per-class breakdown (sorted by accuracy ascending to highlight weak classes)
    per_class: list[dict] = []
    for idx, label in enumerate(LABELS):
        row_total = confusion[idx].sum()
        row_correct = confusion[idx, idx]
        acc = row_correct / row_total if row_total > 0 else 0.0
        per_class.append({"label": label, "accuracy": round(float(acc), 4), "n": int(row_total)})

    per_class.sort(key=lambda x: x["accuracy"])
    print("\n--- Worst 20 classes ---")
    for entry in per_class[:20]:
        print(f"  {entry['label']:4s}  acc={entry['accuracy']:.3f}  n={entry['n']}")

    # Save per-class report
    models_dir = REPO_ROOT / "ml" / "models"
    with open(models_dir / "per_class_accuracy.json", "w", encoding="utf-8") as f:
        json.dump(sorted(per_class, key=lambda x: x["label"]), f, ensure_ascii=False, indent=2)
    print(f"\nPer-class report → {models_dir / 'per_class_accuracy.json'}")

    # Confusion matrix plot
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, ax = plt.subplots(figsize=(22, 20))
        im = ax.imshow(confusion, interpolation="nearest", aspect="auto", cmap="Blues")
        plt.colorbar(im, ax=ax)
        tick_marks = np.arange(num_classes)
        ax.set_xticks(tick_marks)
        ax.set_yticks(tick_marks)
        ax.set_xticklabels(LABELS, rotation=90, fontsize=6)
        ax.set_yticklabels(LABELS, fontsize=6)
        ax.set_ylabel("True label")
        ax.set_xlabel("Predicted label")
        ax.set_title(f"Confusion Matrix — Top-1 accuracy: {top1:.4f}")
        plt.tight_layout()
        out_path = models_dir / "confusion_matrix.png"
        plt.savefig(out_path, dpi=120)
        plt.close()
        print(f"Confusion matrix → {out_path}")
    except ImportError:
        print("matplotlib not installed; skipping confusion matrix plot.")


if __name__ == "__main__":
    evaluate(parse_args())
