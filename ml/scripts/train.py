"""
train.py — Training loop for the KanaFlow kana CNN classifier.

Usage:
    python train.py [--epochs 60] [--batch-size 64] [--lr 1e-3] [--seed 42]

Outputs:
    ml/models/best_model.pt   — best checkpoint (by val loss)
    ml/models/last_model.pt   — final epoch checkpoint
"""

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader

REPO_ROOT = Path(__file__).resolve().parents[2]

import sys
sys.path.insert(0, str(Path(__file__).parent))

from dataset import build_datasets
from model import build_model
from labels import LABELS


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Train KanaFlow CNN classifier")
    p.add_argument("--epochs",      type=int,   default=60)
    p.add_argument("--batch-size",  type=int,   default=64)
    p.add_argument("--lr",          type=float, default=1e-3)
    p.add_argument("--weight-decay",type=float, default=1e-4)
    p.add_argument("--dropout",     type=float, default=0.40)
    p.add_argument("--workers",     type=int,   default=4)
    p.add_argument("--seed",        type=int,   default=42)
    p.add_argument("--val-fraction",type=float, default=0.10)
    p.add_argument("--test-fraction",type=float,default=0.10)
    return p.parse_args()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _device() -> torch.device:
    if torch.cuda.is_available():
        return torch.device("cuda")
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def _accuracy(logits: torch.Tensor, targets: torch.Tensor) -> float:
    preds = logits.argmax(dim=1)
    return (preds == targets).float().mean().item()


# ---------------------------------------------------------------------------
# Training
# ---------------------------------------------------------------------------

def train(args: argparse.Namespace) -> None:
    torch.manual_seed(args.seed)
    device = _device()
    print(f"Using device: {device}")

    # --- Data ---
    train_ds, val_ds, test_ds = build_datasets(
        val_fraction=args.val_fraction,
        test_fraction=args.test_fraction,
        seed=args.seed,
    )
    train_loader = DataLoader(
        train_ds,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=args.workers,
        pin_memory=(device.type == "cuda"),
    )
    val_loader = DataLoader(
        val_ds,
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=args.workers,
        pin_memory=(device.type == "cuda"),
    )

    # --- Model ---
    model = build_model(dropout=args.dropout).to(device)
    n_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"Model parameters: {n_params:,}")

    # --- Optimiser & scheduler ---
    criterion = nn.CrossEntropyLoss(label_smoothing=0.05)
    optimiser = torch.optim.Adam(
        model.parameters(), lr=args.lr, weight_decay=args.weight_decay
    )
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimiser, T_max=args.epochs, eta_min=1e-5
    )

    # --- Output directory ---
    models_dir = REPO_ROOT / "ml" / "models"
    models_dir.mkdir(parents=True, exist_ok=True)

    best_val_loss = float("inf")
    history: list[dict] = []

    for epoch in range(1, args.epochs + 1):
        t0 = time.time()

        # -- Train --
        model.train()
        train_loss = 0.0
        train_acc  = 0.0
        for batch_x, batch_y in train_loader:
            batch_x = batch_x.to(device)
            batch_y = batch_y.to(device)

            optimiser.zero_grad()
            logits = model(batch_x)
            loss = criterion(logits, batch_y)
            loss.backward()
            optimiser.step()

            train_loss += loss.item() * len(batch_y)
            train_acc  += _accuracy(logits, batch_y) * len(batch_y)

        train_loss /= len(train_ds)
        train_acc  /= len(train_ds)

        # -- Validate --
        model.eval()
        val_loss = 0.0
        val_acc  = 0.0
        with torch.no_grad():
            for batch_x, batch_y in val_loader:
                batch_x = batch_x.to(device)
                batch_y = batch_y.to(device)
                logits = model(batch_x)
                loss = criterion(logits, batch_y)
                val_loss += loss.item() * len(batch_y)
                val_acc  += _accuracy(logits, batch_y) * len(batch_y)

        val_loss /= len(val_ds)
        val_acc  /= len(val_ds)

        scheduler.step()
        elapsed = time.time() - t0

        row = {
            "epoch": epoch,
            "train_loss": round(train_loss, 4),
            "train_acc":  round(train_acc,  4),
            "val_loss":   round(val_loss,   4),
            "val_acc":    round(val_acc,    4),
            "lr":         round(scheduler.get_last_lr()[0], 6),
        }
        history.append(row)

        print(
            f"Epoch {epoch:3d}/{args.epochs} | "
            f"train loss={train_loss:.4f} acc={train_acc:.3f} | "
            f"val loss={val_loss:.4f} acc={val_acc:.3f} | "
            f"lr={row['lr']:.2e} | {elapsed:.1f}s"
        )

        # -- Checkpoint --
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            torch.save(
                {"epoch": epoch, "model_state": model.state_dict(), "val_acc": val_acc},
                models_dir / "best_model.pt",
            )
            print(f"  ✓ New best checkpoint (val_loss={val_loss:.4f})")

    # Save last checkpoint and history
    torch.save(
        {"epoch": args.epochs, "model_state": model.state_dict()},
        models_dir / "last_model.pt",
    )
    with open(models_dir / "training_history.json", "w") as f:
        json.dump(history, f, indent=2)

    print(f"\nTraining complete. Best val loss: {best_val_loss:.4f}")
    print(f"Checkpoints saved to {models_dir}")


if __name__ == "__main__":
    train(parse_args())
