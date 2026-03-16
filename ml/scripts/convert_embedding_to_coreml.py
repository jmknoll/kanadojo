"""
convert_embedding_to_coreml.py

Export the KanaEmbedder network (features + gap + embed + L2 normalize)
to a Core ML neuralnetwork package targeting iOS 14+.

Input:  "input"     — (1, 1, 64, 64) float32
Output: "embedding" — (1, 128) float32, L2-normalized

Output: KanaFlow/KanaFlow/Models/KanaEmbedder.mlpackage

Usage:
  python convert_embedding_to_coreml.py [--checkpoint ml/models/best_embedder.pt]
"""

import argparse
import sys
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))

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
# Export wrapper: embedding only, no ArcFace head
# ---------------------------------------------------------------------------

class EmbedNetOnly(nn.Module):
    """Wraps KanaEmbedder for export — features + gap + embed + L2 normalize.

    Identical computation to KanaEmbedder.forward(), but packaged as a
    standalone module so the ArcFace head is cleanly excluded.
    """

    def __init__(self, embedder: KanaEmbedder) -> None:
        super().__init__()
        self.features = embedder.features
        self.gap = embedder.gap
        self.embed = embedder.embed

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.features(x)
        x = self.gap(x).flatten(1)
        x = self.embed(x)
        return F.normalize(x, p=2, dim=1)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export KanaEmbedder to Core ML neuralnetwork"
    )
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

    # ── Load model ────────────────────────────────────────────────────────────
    device = torch.device("cpu")  # Core ML export must happen on CPU
    print(f"Loading checkpoint: {checkpoint_path}")

    embedder = KanaEmbedder()
    state = torch.load(checkpoint_path, map_location=device)
    if isinstance(state, dict) and "model_state_dict" in state:
        embedder.load_state_dict(state["model_state_dict"])
        epoch = state.get("epoch", "?")
        val_loss = state.get("val_loss", float("nan"))
        print(f"  Loaded from epoch {epoch} (val_loss={val_loss:.4f})")
    else:
        embedder.load_state_dict(state)
    embedder.eval()

    # ── Build export wrapper ──────────────────────────────────────────────────
    export_model = EmbedNetOnly(embedder)
    export_model.eval()

    # ── Trace with TorchScript ────────────────────────────────────────────────
    example_input = torch.zeros(1, 1, 64, 64)
    print("Tracing model...")
    with torch.no_grad():
        traced = torch.jit.trace(export_model, example_input)

    # Verify output shape
    with torch.no_grad():
        out = traced(example_input)
    assert out.shape == (1, 128), f"Unexpected output shape: {out.shape}"
    norm = out.norm(dim=1).item()
    assert abs(norm - 1.0) < 1e-5, f"Output not L2-normalized: norm={norm:.6f}"
    print(f"  Output shape: {out.shape}  (L2 norm={norm:.6f} ✓)")

    # ── Convert to Core ML ────────────────────────────────────────────────────
    try:
        import coremltools as ct
    except ImportError:
        print("ERROR: coremltools not installed. Run: pip install coremltools")
        sys.exit(1)

    print("Converting to Core ML (neuralnetwork, iOS 14)...")

    mlmodel = ct.convert(
        traced,
        inputs=[
            ct.ImageType(
                name="input",
                shape=(1, 1, 64, 64),
                color_layout=ct.colorlayout.GRAYSCALE,
                scale=1.0 / 255.0,
                bias=0.0,
            )
        ],
        convert_to="neuralnetwork",
        minimum_deployment_target=ct.target.iOS14,
    )

    # Rename output to "embedding"
    spec = mlmodel.get_spec()
    ct.utils.rename_feature(spec, spec.description.output[0].name, "embedding")
    mlmodel = ct.models.MLModel(spec)

    # Add metadata
    mlmodel.short_description = "KanaEmbedder: 128-dim L2-normalized embedding for kana handwriting"
    mlmodel.input_description["input"] = "64×64 grayscale image of a handwritten kana character"
    mlmodel.output_description["embedding"] = "128-dimensional L2-normalized embedding vector"
    mlmodel.version = "1.0"
    mlmodel.author = "KanaFlow ML pipeline"

    # ── Save ─────────────────────────────────────────────────────────────────
    out_path = REPO_ROOT / "KanaFlow" / "KanaFlow" / "Models" / "KanaEmbedderModel.mlpackage"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Saving to {out_path} ...")
    mlmodel.save(str(out_path))
    print(f"Done. Saved → {out_path}")

    # ── Quick sanity-check via Core ML prediction ─────────────────────────────
    try:
        import numpy as np
        from PIL import Image

        dummy_img = Image.fromarray(
            np.full((64, 64), 200, dtype=np.uint8), mode="L"
        )
        prediction = mlmodel.predict({"input": dummy_img})
        emb = prediction["embedding"]
        emb_norm = float(np.linalg.norm(emb))
        print(f"\nSanity check — output norm: {emb_norm:.6f} (should be ≈1.0)")
    except Exception as e:
        print(f"\nSanity check skipped ({type(e).__name__}: {e})")


if __name__ == "__main__":
    main()
