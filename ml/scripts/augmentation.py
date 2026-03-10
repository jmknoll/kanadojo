"""
augmentation.py — Albumentations augmentation pipeline for training.

Applied on-the-fly in dataset.py during training. Validation/test splits
use only the resize+normalize transform.

Input:  64×64 uint8 grayscale numpy array (ink dark ~111-150, background ~190-220)
Output: 64×64 float32 tensor [0, 1], same ink/background convention
"""

from __future__ import annotations

import numpy as np


def _make_train_transform():
    """Return the Albumentations transform for training."""
    import albumentations as A
    from albumentations.pytorch import ToTensorV2

    return A.Compose(
        [
            # Geometric — use Affine (ShiftScaleRotate deprecated in v2)
            A.Affine(
                translate_percent={"x": (-0.05, 0.05), "y": (-0.05, 0.05)},
                scale=(0.88, 1.12),
                rotate=(-15, 15),
                border_mode=0,      # cv2.BORDER_CONSTANT
                fill=220,           # background fill value (uint8)
                p=0.85,
            ),
            A.ElasticTransform(
                alpha=18.0,
                sigma=5.0,
                p=0.45,
            ),
            A.Perspective(scale=(0.02, 0.07), p=0.30),

            # Morphological stroke-width variation
            A.OneOf(
                [
                    A.Morphological(scale=(2, 3), operation="dilation", p=1.0),
                    A.Morphological(scale=(2, 3), operation="erosion",  p=1.0),
                ],
                p=0.35,
            ),

            # Pixel-level noise (mild — images are already clean)
            # std_range is a fraction of max pixel value (255), so (2/255, 8/255) ≈ (0.008, 0.031)
            A.GaussNoise(std_range=(0.008, 0.031), p=0.25),
            A.Blur(blur_limit=3, p=0.15),

            # Normalize: pixel / 255 → float32 [0, 1]
            A.Normalize(mean=0.0, std=1.0, max_pixel_value=255.0),
            ToTensorV2(),
        ]
    )


def _make_val_transform():
    """Return the minimal transform for validation/test."""
    import albumentations as A
    from albumentations.pytorch import ToTensorV2

    return A.Compose(
        [
            A.Normalize(mean=0.0, std=1.0, max_pixel_value=255.0),
            ToTensorV2(),
        ]
    )


# Module-level singletons (lazy-loaded)
_train_transform = None
_val_transform = None


def get_train_transform():
    global _train_transform
    if _train_transform is None:
        _train_transform = _make_train_transform()
    return _train_transform


def get_val_transform():
    global _val_transform
    if _val_transform is None:
        _val_transform = _make_val_transform()
    return _val_transform


def apply_train(image: np.ndarray):
    """
    Apply training augmentation to a single HW uint8 grayscale image.
    Returns a (1, H, W) float32 tensor.
    """
    result = get_train_transform()(image=image)
    return result["image"]


def apply_val(image: np.ndarray):
    """
    Apply val/test transform to a single HW uint8 grayscale image.
    Returns a (1, H, W) float32 tensor.
    """
    result = get_val_transform()(image=image)
    return result["image"]
