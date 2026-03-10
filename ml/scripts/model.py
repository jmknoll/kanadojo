"""
model.py — KanaFlow CNN classifier architecture.

Input:  (batch, 1, 64, 64) float32, values in [0, 1]
Output: (batch, 92) logits (softmax applied at export/inference time)

Architecture: 4 conv blocks (Conv → BN → ReLU → MaxPool) + GlobalAvgPool → FC(214)
~3M parameters, fast enough for on-device Core ML inference.
"""

from __future__ import annotations

import torch
import torch.nn as nn


class ConvBlock(nn.Module):
    """Conv2d → BatchNorm2d → ReLU → MaxPool2d."""

    def __init__(
        self,
        in_channels: int,
        out_channels: int,
        kernel_size: int = 3,
        pool: bool = True,
    ) -> None:
        super().__init__()
        layers: list[nn.Module] = [
            nn.Conv2d(in_channels, out_channels, kernel_size, padding=kernel_size // 2, bias=False),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True),
        ]
        if pool:
            layers.append(nn.MaxPool2d(2, 2))
        self.block = nn.Sequential(*layers)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.block(x)


class KanaCNN(nn.Module):
    """
    4-block CNN for 214-class kana recognition.

    Spatial progression (64×64 input):
        Block 1: 64×64 → 32×32  (32 ch)
        Block 2: 32×32 → 16×16  (64 ch)
        Block 3: 16×16 → 8×8    (128 ch)
        Block 4: 8×8  → 4×4     (256 ch)
        GlobalAvgPool: 256×4×4 → 256
        FC: 256 → 214
    """

    NUM_CLASSES = 92

    def __init__(self, num_classes: int = NUM_CLASSES, dropout: float = 0.4) -> None:
        super().__init__()

        self.features = nn.Sequential(
            ConvBlock(1,    32,  pool=True),   # → 32×32
            ConvBlock(32,   64,  pool=True),   # → 16×16
            ConvBlock(64,   128, pool=True),   # → 8×8
            ConvBlock(128,  256, pool=True),   # → 4×4
        )

        # Global average pooling: (B, 256, 4, 4) → (B, 256)
        self.gap = nn.AdaptiveAvgPool2d(1)

        self.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(256, num_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.features(x)           # (B, 256, 4, 4)
        x = self.gap(x)                # (B, 256, 1, 1)
        x = x.flatten(1)               # (B, 256)
        x = self.classifier(x)         # (B, 214) logits
        return x


def build_model(num_classes: int = 92, dropout: float = 0.4) -> KanaCNN:
    return KanaCNN(num_classes=num_classes, dropout=dropout)


if __name__ == "__main__":
    model = build_model()
    dummy = torch.zeros(2, 1, 64, 64)
    out = model(dummy)
    print(f"Output shape: {out.shape}")  # (2, 214)
    n_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"Trainable parameters: {n_params:,}")
