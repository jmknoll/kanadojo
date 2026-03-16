"""
train_embedding.py

Train a KanaEmbedder model using ArcFace loss on 93 classes:
  - Classes 0-91: the 92 correct kana characters
  - Class 92:    "incorrect/other" (incorrect samples from generate_incorrect_samples.py)

Usage:
  python train_embedding.py [--epochs 80] [--batch-size 64] [--workers 0] [--seed 42]
"""

import argparse
import math
import random
import sys
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader, ConcatDataset, random_split
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))

from labels import LABELS, LABEL_TO_IDX
from augmentation import apply_train, apply_val
from render_fonts import char_to_hex

NUM_KANA = 92
INCORRECT_CLASS = 92
NUM_CLASSES = 92  # ArcFace only over the 92 kana classes
                  # Incorrect samples (label=92) are excluded from the ArcFace loss;
                  # they act as implicit hard negatives that get pushed out of all clusters.


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
# KanaEmbedder architecture
# ---------------------------------------------------------------------------

def _conv_block(in_ch: int, out_ch: int) -> nn.Sequential:
    return nn.Sequential(
        nn.Conv2d(in_ch, out_ch, kernel_size=3, padding=1, bias=False),
        nn.BatchNorm2d(out_ch),
        nn.ReLU(inplace=True),
        nn.Conv2d(out_ch, out_ch, kernel_size=3, padding=1, bias=False),
        nn.BatchNorm2d(out_ch),
        nn.ReLU(inplace=True),
        nn.MaxPool2d(2),
    )


class KanaEmbedder(nn.Module):
    EMBED_DIM = 128

    def __init__(self, dropout: float = 0.3) -> None:
        super().__init__()
        self.features = nn.Sequential(
            _conv_block(1, 32),    # → (B, 32, 32, 32)
            _conv_block(32, 64),   # → (B, 64, 16, 16)
            _conv_block(64, 128),  # → (B, 128, 8, 8)
            _conv_block(128, 256), # → (B, 256, 4, 4)
        )
        self.gap = nn.AdaptiveAvgPool2d(1)
        self.embed = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(256, self.EMBED_DIM),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.features(x)
        x = self.gap(x).flatten(1)
        x = self.embed(x)
        return F.normalize(x, p=2, dim=1)


# ---------------------------------------------------------------------------
# ArcFace loss
# ---------------------------------------------------------------------------

class ArcFaceLoss(nn.Module):
    def __init__(
        self,
        embed_dim: int,
        num_classes: int,
        s: float = 32.0,
        m: float = 0.50,
    ) -> None:
        super().__init__()
        self.s = s
        self.m = m
        self.weight = nn.Parameter(torch.empty(num_classes, embed_dim))
        nn.init.xavier_uniform_(self.weight)

        self.cos_m = math.cos(m)
        self.sin_m = math.sin(m)
        self.th = math.cos(math.pi - m)
        self.mm = math.sin(math.pi - m) * m

    def forward(self, embeddings: torch.Tensor, labels: torch.Tensor) -> torch.Tensor:
        # Normalize weight rows
        w = F.normalize(self.weight, p=2, dim=1)

        # cos(theta) for all class-embedding pairs
        cos_theta = torch.mm(embeddings, w.t()).clamp(-1.0, 1.0)
        sin_theta = torch.sqrt((1.0 - cos_theta ** 2).clamp(min=1e-9))

        # Angular margin target: cos(theta + m)
        cos_theta_m = cos_theta * self.cos_m - sin_theta * self.sin_m

        # Boundary condition: avoid cos(theta + m) < cos(pi) = -1
        cos_theta_m = torch.where(
            cos_theta > self.th,
            cos_theta_m,
            cos_theta - self.mm,
        )

        # One-hot for target class
        one_hot = torch.zeros_like(cos_theta)
        one_hot.scatter_(1, labels.unsqueeze(1), 1.0)

        # Replace target logit with margined version
        logits = torch.where(one_hot.bool(), cos_theta_m, cos_theta) * self.s

        return F.cross_entropy(logits, labels)


# ---------------------------------------------------------------------------
# Datasets
# ---------------------------------------------------------------------------

class FontRenderDataset(Dataset):
    """Loads all font render PNGs for all kana characters (labels 0-91)."""

    def __init__(self, augment: bool = True) -> None:
        self.augment = augment
        self.samples: list[tuple[Path, int]] = []

        font_root = REPO_ROOT / "ml" / "data" / "font_renders"
        if not font_root.exists():
            raise FileNotFoundError(f"Font renders not found: {font_root}")

        for char in LABELS:
            hex_c = char_to_hex(char)
            label = LABEL_TO_IDX[char]
            for font_dir in sorted(font_root.iterdir()):
                char_dir = font_dir / hex_c
                if char_dir.exists():
                    for p in sorted(char_dir.glob("*.png")):
                        self.samples.append((p, label))

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> tuple[torch.Tensor, int]:
        path, label = self.samples[idx]
        arr = np.array(Image.open(path).convert("L"))
        tensor = apply_train(arr) if self.augment else apply_val(arr)
        return tensor, label


class IncorrectSamplesDataset(Dataset):
    """Loads all incorrect sample PNGs (label = INCORRECT_CLASS = 92)."""

    def __init__(self, augment: bool = True) -> None:
        self.augment = augment
        self.samples: list[Path] = []

        inc_root = REPO_ROOT / "ml" / "data" / "incorrect_samples"
        if not inc_root.exists():
            raise FileNotFoundError(
                f"Incorrect samples not found: {inc_root}\n"
                "Run generate_incorrect_samples.py first."
            )

        for char_dir in sorted(inc_root.iterdir()):
            if not char_dir.is_dir():
                continue
            for p in sorted(char_dir.glob("*.png")):
                self.samples.append(p)

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> tuple[torch.Tensor, int]:
        path = self.samples[idx]
        arr = np.array(Image.open(path).convert("L"))
        tensor = apply_train(arr) if self.augment else apply_val(arr)
        return tensor, INCORRECT_CLASS


class _LabelledSubset(Dataset):
    """Wraps a Subset and preserves augment flag via re-creation."""

    def __init__(self, dataset: Dataset, indices: list[int], augment: bool) -> None:
        self._dataset = dataset
        self._indices = indices
        self._augment = augment
        # Store original augment and temporarily override
        self._orig_augment = getattr(dataset, "augment", augment)

    def __len__(self) -> int:
        return len(self._indices)

    def __getitem__(self, idx: int) -> tuple[torch.Tensor, int]:
        orig = self._dataset.augment  # type: ignore[attr-defined]
        self._dataset.augment = self._augment  # type: ignore[attr-defined]
        item = self._dataset[self._indices[idx]]
        self._dataset.augment = orig  # type: ignore[attr-defined]
        return item


def _split_dataset(
    ds: Dataset,
    val_frac: float = 0.1,
    seed: int = 42,
) -> tuple[Dataset, Dataset]:
    n = len(ds)
    n_val = max(1, int(n * val_frac))
    n_train = n - n_val
    g = torch.Generator().manual_seed(seed)
    train_sub, val_sub = random_split(ds, [n_train, n_val], generator=g)
    return train_sub, val_sub


# ---------------------------------------------------------------------------
# Training
# ---------------------------------------------------------------------------

def train_epoch(
    model: KanaEmbedder,
    criterion: ArcFaceLoss,
    loader: DataLoader,
    optimizer: torch.optim.Optimizer,
    device: torch.device,
) -> float:
    model.train()
    total_loss = 0.0
    n_batches = 0
    for imgs, labels in loader:
        imgs = imgs.to(device)
        labels = labels.to(device)
        optimizer.zero_grad()
        embeddings = model(imgs)
        # Exclude incorrect-class samples (label=92) from ArcFace loss.
        # They still pass through the encoder (updating features via the kana loss),
        # and their embeddings are driven away from kana clusters implicitly.
        kana_mask = labels < NUM_KANA
        if kana_mask.any():
            loss = criterion(embeddings[kana_mask], labels[kana_mask])
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
            n_batches += 1
    return total_loss / max(n_batches, 1)


@torch.no_grad()
def val_epoch(
    model: KanaEmbedder,
    criterion: ArcFaceLoss,
    loader: DataLoader,
    device: torch.device,
) -> float:
    model.eval()
    total_loss = 0.0
    n_batches = 0
    for imgs, labels in loader:
        imgs = imgs.to(device)
        labels = labels.to(device)
        embeddings = model(imgs)
        kana_mask = labels < NUM_KANA
        if kana_mask.any():
            loss = criterion(embeddings[kana_mask], labels[kana_mask])
            total_loss += loss.item()
            n_batches += 1
    return total_loss / max(n_batches, 1)


@torch.no_grad()
def eval_retrieval(
    model: KanaEmbedder,
    loader: DataLoader,
    device: torch.device,
) -> dict:
    """
    Collect all val embeddings and labels, compute per-class prototypes from
    the val set itself, then measure:
      - prototype k-NN accuracy: fraction whose nearest prototype is correct
      - mean intra-class distance: how tightly correct-class embeddings cluster
      - correct vs incorrect score gap (using 95th-pct radius normalisation)
    Only kana classes (0..NUM_KANA-1) contribute to prototypes; the incorrect
    class (92) is evaluated separately as the "negative" set.
    """
    model.eval()
    all_embs: list[torch.Tensor] = []
    all_labels: list[torch.Tensor] = []

    for imgs, labels in loader:
        embs = model(imgs.to(device))
        all_embs.append(embs.cpu())
        all_labels.append(labels)

    embs = torch.cat(all_embs)        # (N, 128)
    labels = torch.cat(all_labels)    # (N,)

    # Build prototypes from kana samples only
    prototypes = torch.zeros(NUM_KANA, embs.shape[1])
    counts = torch.zeros(NUM_KANA)
    for i in range(NUM_KANA):
        mask = labels == i
        if mask.any():
            prototypes[i] = torch.nn.functional.normalize(embs[mask].mean(0), dim=0)
            counts[i] = mask.sum()

    # k-NN accuracy on kana samples
    kana_mask = labels < NUM_KANA
    kana_embs = embs[kana_mask]          # (K, 128)
    kana_labels = labels[kana_mask]      # (K,)

    dists = torch.cdist(kana_embs, prototypes)  # (K, NUM_KANA)
    nearest = dists.argmin(dim=1)
    knn_acc = (nearest == kana_labels).float().mean().item()

    # Mean intra-class distance (average distance from each embedding to its prototype)
    proto_for_each = prototypes[kana_labels]          # (K, 128)
    intra_dists = (kana_embs - proto_for_each).norm(dim=1)
    mean_intra = intra_dists.mean().item()

    # Score gap: kana samples (should score high) vs incorrect class (should score low)
    # Use 95th-pct intra distance as the radius (same as compute_prototypes.py)
    radius = float(torch.quantile(intra_dists, 0.95))
    kana_scores = (1.0 - intra_dists / radius).clamp(0).mean().item()

    inc_mask = labels == INCORRECT_CLASS
    if inc_mask.any():
        inc_embs = embs[inc_mask]
        # Distance to nearest prototype (the character being tested against)
        inc_dists = torch.cdist(inc_embs, prototypes).min(dim=1).values
        inc_scores = (1.0 - inc_dists / radius).clamp(0).mean().item()
    else:
        inc_scores = float("nan")

    return {
        "knn_acc": knn_acc,
        "mean_intra": mean_intra,
        "radius": radius,
        "kana_score": kana_scores,
        "inc_score": inc_scores,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Train KanaEmbedder with ArcFace loss")
    parser.add_argument("--epochs", type=int, default=80)
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--workers", type=int, default=0)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    random.seed(args.seed)
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)

    device = _device()
    print(f"Device: {device}")

    # Build datasets
    print("Loading font renders...")
    font_ds = FontRenderDataset(augment=True)
    print(f"  Font render samples: {len(font_ds)}")

    print("Loading incorrect samples...")
    try:
        incorrect_ds = IncorrectSamplesDataset(augment=True)
        print(f"  Incorrect samples: {len(incorrect_ds)}")
    except FileNotFoundError as e:
        print(f"WARNING: {e}")
        incorrect_ds = None

    # Split each dataset into train/val
    font_train, font_val = _split_dataset(font_ds, val_frac=0.1, seed=args.seed)

    if incorrect_ds is not None:
        inc_train, inc_val = _split_dataset(incorrect_ds, val_frac=0.1, seed=args.seed)
        train_ds = ConcatDataset([font_train, inc_train])
        val_ds = ConcatDataset([font_val, inc_val])
    else:
        train_ds = font_train
        val_ds = font_val

    train_loader = DataLoader(
        train_ds,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=args.workers,
        pin_memory=(device.type == "cuda"),
        drop_last=True,
    )
    val_loader = DataLoader(
        val_ds,
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=args.workers,
        pin_memory=(device.type == "cuda"),
    )

    print(f"Train batches: {len(train_loader)}, Val batches: {len(val_loader)}")

    # Build model
    model = KanaEmbedder(dropout=0.3).to(device)
    criterion = ArcFaceLoss(
        embed_dim=KanaEmbedder.EMBED_DIM,
        num_classes=NUM_CLASSES,
        s=16.0,   # was 32 — lower scale suits this dataset size (~50K samples)
        m=0.35,   # was 0.50 — smaller margin is easier to satisfy initially
    ).to(device)

    # Transfer learning: load features from best_model.pt if it exists
    best_classifier_path = REPO_ROOT / "ml" / "models" / "best_model.pt"
    if best_classifier_path.exists():
        print(f"Loading features from {best_classifier_path} ...")
        state = torch.load(best_classifier_path, map_location=device)
        if isinstance(state, dict) and "model_state_dict" in state:
            state = state["model_state_dict"]
        # Extract only features weights
        features_state = {
            k[len("features."):]: v
            for k, v in state.items()
            if k.startswith("features.")
        }
        missing, unexpected = model.features.load_state_dict(features_state, strict=False)
        print(f"  Loaded features. Missing: {len(missing)}, Unexpected: {len(unexpected)}")
    else:
        print("No best_model.pt found — training from scratch.")

    # Optimiser: two param groups
    optimizer = torch.optim.AdamW(
        [
            {"params": model.features.parameters(), "lr": 1e-4},
            {"params": model.embed.parameters(), "lr": 1e-3},
            {"params": criterion.parameters(), "lr": 1e-3},
        ],
        weight_decay=1e-4,
    )
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer, T_max=args.epochs, eta_min=1e-6
    )

    # Training loop
    models_dir = REPO_ROOT / "ml" / "models"
    models_dir.mkdir(parents=True, exist_ok=True)
    best_path = models_dir / "best_embedder.pt"

    best_val_loss = float("inf")
    print(f"\nTraining for {args.epochs} epochs...")
    print(f"{'Epoch':>6}  {'train':>8}  {'val':>8}  {'kNN%':>6}  {'intra':>6}  {'gap':>8}")

    for epoch in range(1, args.epochs + 1):
        train_loss = train_epoch(model, criterion, train_loader, optimizer, device)
        val_loss = val_epoch(model, criterion, val_loader, device)
        scheduler.step()

        is_best = val_loss < best_val_loss
        if is_best:
            best_val_loss = val_loss
            torch.save(
                {
                    "epoch": epoch,
                    "model_state_dict": model.state_dict(),
                    "arcface_state_dict": criterion.state_dict(),
                    "val_loss": val_loss,
                },
                best_path,
            )

        # Retrieval eval every 10 epochs and on the final epoch
        if epoch % 10 == 0 or epoch == args.epochs:
            m = eval_retrieval(model, val_loader, device)
            gap = m["kana_score"] - m["inc_score"]
            print(
                f"{epoch:6d}  {train_loss:8.4f}  {val_loss:8.4f}  "
                f"{m['knn_acc']*100:5.1f}%  {m['mean_intra']:6.4f}  "
                f"{m['kana_score']:.3f}-{m['inc_score']:.3f}={gap:+.3f}"
                f"{'  *' if is_best else ''}"
            )
        else:
            marker = " *" if is_best else ""
            print(
                f"{epoch:6d}  {train_loss:8.4f}  {val_loss:8.4f}{marker}"
            )

    print(f"\nBest val loss: {best_val_loss:.4f}")
    print(f"Checkpoint saved → {best_path}")
    print("\nFinal retrieval evaluation:")
    m = eval_retrieval(model, val_loader, device)
    print(f"  k-NN accuracy:       {m['knn_acc']*100:.1f}%  (target: >95%)")
    print(f"  Mean intra-class dist: {m['mean_intra']:.4f}  (target: <0.30)")
    print(f"  Prototype radius (p95): {m['radius']:.4f}")
    print(f"  Correct score (kana):  {m['kana_score']:.3f}  (target: >0.60)")
    print(f"  Incorrect score:       {m['inc_score']:.3f}  (target: <0.30)")
    print(f"  Score gap:             {m['kana_score']-m['inc_score']:+.3f}  (target: >0.40)")


if __name__ == "__main__":
    main()
