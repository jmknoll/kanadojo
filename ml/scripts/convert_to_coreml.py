"""
convert_to_coreml.py — Export a trained PyTorch model to Core ML.

Usage:
    python convert_to_coreml.py [--checkpoint ml/models/best_model.pt]

Outputs:
    KanaFlow/KanaFlow/Models/KanaClassifier.mlpackage   (Core ML model)
    KanaFlow/KanaFlow/Models/kana_labels.json           (214-element label list)

The exported model:
  - Input:  "input"  shape (1, 1, 64, 64) float32, values in [0, 1]
  - Output: "classLabelProbs"  shape (214,) softmax probabilities
  - userDefinedMetadata["labels"] = JSON-encoded LABELS list

Requires:
    pip install coremltools torch
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import torch
import torch.nn as nn

REPO_ROOT = Path(__file__).resolve().parents[2]
MODELS_DIR   = REPO_ROOT / "KanaFlow" / "Models"
SCRIPTS_DIR  = Path(__file__).parent

import sys
sys.path.insert(0, str(SCRIPTS_DIR))

from model import build_model
from labels import LABELS


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument(
        "--checkpoint",
        default=str(REPO_ROOT / "ml" / "models" / "best_model.pt"),
    )
    return p.parse_args()


class ModelWithSoftmax(nn.Module):
    """Wrap the CNN with a softmax so Core ML receives probabilities."""

    def __init__(self, base: nn.Module) -> None:
        super().__init__()
        self.base = base

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        logits = self.base(x)
        return torch.softmax(logits, dim=1)


def convert(args: argparse.Namespace) -> None:
    import coremltools as ct

    # --- Load model ---
    base_model = build_model()
    ckpt = torch.load(args.checkpoint, map_location="cpu", weights_only=True)
    base_model.load_state_dict(ckpt["model_state"])
    base_model.eval()
    print(f"Loaded checkpoint from epoch {ckpt.get('epoch', '?')}")

    wrapped = ModelWithSoftmax(base_model)
    wrapped.eval()

    # --- Trace ---
    example_input = torch.zeros(1, 1, 64, 64)
    traced = torch.jit.trace(wrapped, example_input)
    print("TorchScript trace complete.")

    # --- Convert ---
    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="input", shape=(1, 1, 64, 64))],
        outputs=[ct.TensorType(name="classLabelProbs")],
        minimum_deployment_target=ct.target.iOS14,
        convert_to="neuralnetwork",
    )

    # Embed label metadata
    mlmodel.user_defined_metadata["labels"] = json.dumps(LABELS, ensure_ascii=False)
    mlmodel.user_defined_metadata["num_classes"] = str(len(LABELS))
    mlmodel.user_defined_metadata["input_size"] = "64x64"
    mlmodel.user_defined_metadata["normalisation"] = "pixel/255 (uint8→float32)"

    # --- Save ---
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    out_path = MODELS_DIR / "KanaClassifier.mlpackage"
    mlmodel.save(str(out_path))
    print(f"Core ML model saved → {out_path}")

    # --- Labels JSON (for Swift reference) ---
    labels_path = MODELS_DIR / "kana_labels.json"
    with open(labels_path, "w", encoding="utf-8") as f:
        json.dump(LABELS, f, ensure_ascii=False, indent=2)
    print(f"Labels JSON saved   → {labels_path}")


if __name__ == "__main__":
    convert(parse_args())
