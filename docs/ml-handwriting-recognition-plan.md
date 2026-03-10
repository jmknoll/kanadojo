# ML Handwriting Recognition — Implementation Plan

## Status: ETL4/5 pre-processed and ready. Implement from Phase A step 2 onwards.

## Background

Phase 5 originally proposed a DTW (Dynamic Time Warping) stroke-matching approach. That implementation (`StrokeRecognition.swift`) is complete but proved a dead end: DTW measures geometric path fidelity rather than legibility, producing unreliable scores that don't correlate with how well the user can actually write a character. It is being replaced entirely.

`GradingOverlayView.swift` was partially wired up for the DTW approach but never connected to the quiz flow. `QuizPlayView.swift` still references the non-existent `SelfGradeOverlayView` struct, so the project currently does not compile on `master`.

This plan fixes the compile error and implements the ML-based replacement end to end.

---

## Approach

A small CNN-based image classifier runs fully on-device via Core ML. Given a rendered bitmap of the user's handwritten strokes, the model outputs a probability distribution over all 214 character classes. The probability assigned to the correct class is the legibility score. A well-formed character scores high; a poorly-formed one scores low, even if technically the right character.

**Why this beats DTW:**
- DTW scores path similarity, not legibility. A perfectly-drawn character done in an unusual stroke order can score poorly; a scribbly character drawn in the right order can score well.
- The CNN's probability reflects genuine perceptual similarity to real handwriting samples, which is exactly what we want to measure.

---

## Scope

### What this plan covers
- Full ML training pipeline (Python / PyTorch)
- Core ML model conversion and bundling
- iOS `KanaRecognizer` service
- Wiring into the quiz flow (fixing the current compile error)
- Updating `GradingOverlayView` to use ML score instead of `StrokeScores`

### What this plan does NOT cover
- Stats page overhaul (spider chart, per-character score history) — deferred to Phase 5.3
- `CharacterProgress` schema migration for per-attempt score fields — deferred to Phase 5.1
- Notifications (Phase 6.0)

---

## Dataset

**ETL4** — hiragana. **ETL5** — katakana. Both from AIST ETL Character Database.

ETL4 and ETL5 were chosen over ETL8B because they have ~38× more samples per class and richer 4-bit grayscale images (vs ETL8B's 1-bit binary). Both scripts are purpose-built for exactly the two scripts the app covers.

### ETL4 (hiragana) and ETL5 (katakana) — pre-processed

The raw ETL4/5 files have already been converted to PNG images by the user. The processed output is in `ml/data/processed/ETL4/` and `ml/data/processed/ETL5/`.

**Actual structure (confirmed by inspection):**
- Image size: **72×76 pixels, grayscale (L mode)** — resized to 64×64 at training time
- Directory naming: hex codepoint (e.g. `0x3042/` for あ)
- Character identity: `.char.txt` file inside each directory contains the Unicode character
- Samples per class: 120 or 240 (ETL4), 208 or 416 (ETL5) — bimodal due to multiple writer cohorts
- **Character coverage: main kana only — 46 hiragana + 46 katakana = 92 classes**
  - ETL4 also includes ぃ and ぇ (small i/e), ETL5 includes ィ and ェ — not quizzed by the app, ignored
  - **Dakuten variants are not present in either dataset**
  - **Small kana (ゃ ゅ ょ etc.) are not present**

### Image normalisation

Pre-processed PNGs are 8-bit grayscale. Ink is dark (low values near 0), paper is light (high values near 255). Normalise for training:

```python
pixel_float = pixel_uint8 / 255.0  # 0.0 = ink, 1.0 = paper
```

This matches inference, where the Swift renderer fills with white (1.0) and draws black strokes (0.0).

---

## Class Taxonomy — 214 Classes

All 214 characters in `KanaData.allCharacters` become model output classes. Sorted lexicographically by Unicode for canonical label ordering.

| Group | Count | Source |
|---|---|---|
| Hiragana main (single) | 46 | ETL4 direct |
| Hiragana dakuten (single) | 25 | Synthetic — ETL4 base + overlaid dakuten mark |
| Katakana main (single) | 46 | ETL5 direct |
| Katakana dakuten (single) | 25 | Synthetic — ETL5 base + overlaid dakuten mark |
| Hiragana combination (2-char) | 36 | Composited from ETL4 (left) + ETL4 or synthetic (left-dakuten) + ETL4 full-size (right) |
| Katakana combination (2-char) | 36 | Composited from ETL5 (left) + ETL5 or synthetic (left-dakuten) + ETL5 full-size (right) |
| **Total** | **214** | |

**On small kana for combination right components:** ゃ ゅ ょ (and ャ ュ ョ) are not in ETL4/5, but separate images are not needed. The compositing step scales the right component to 40% of the 64×64 canvas (~26px). ETL4/5 images of the full-size equivalents (や ゆ よ / ヤ ユ ヨ) are used — the scaling naturally produces the appearance of a small kana.

---

## Dakuten Kana — Synthetic Image Generation

ETL4/5 contains only main kana. All 50 dakuten characters (25 hiragana + 25 katakana) must be synthesised.

**Method:** overlay a rendered dakuten (゛) or handakuten (゜) mark onto ETL4/5 base character images.

- The mark is rendered from a system Japanese font (Hiragino Sans, available on macOS) at a small size appropriate for the mark region
- It is placed at the **top-right** of the character, which is where dakuten appears in standard Japanese writing
- Per-sample jitter is applied to mark position (±3px), scale (±10%), and rotation (±10°) before compositing
- The composited image goes through the same augmentation pipeline as all other images

**Base→dakuten mapping (hiragana):**
```
か き く け こ → が ぎ ぐ げ ご
さ し す せ そ → ざ じ ず ぜ ぞ
た ち つ て と → だ ぢ づ で ど
は ひ ふ へ ほ → ば び ぶ べ ぼ  (゛)
は ひ ふ へ ほ → ぱ ぴ ぷ ぺ ぽ  (゜)
```
Same pattern for katakana (カ→ガ etc.).

**Why not font rendering for the full character?** The base stroke is already handwritten ETL data, which is more representative of user input than a pure font rendering. Only the small mark — which looks essentially the same handwritten or printed — is font-derived.

**Sample count:** generate one synthetic image per ETL4/5 base image → same number of samples as the base class (120–416 per dakuten class depending on the base character). Apply augmentation on the fly during training to further expand effective data volume.

---

## Combination Kana — Synthetic Image Generation

Combination kana (e.g. きゃ) are two-character strings. ETL4/5 has samples for the non-dakuten left components (き し ち に ひ み り / キ シ チ ニ ヒ ミ リ); synthetic dakuten images (from the previous step) cover the dakuten left components (ぎ じ ぢ び ぴ / ギ ジ ヂ ビ ピ); and ETL4/5 full-size equivalents (や ゆ よ / ヤ ユ ヨ) serve as the right components (scaled down by the compositing step). We synthesise combination training images by compositing two component samples onto a shared 64×64 canvas, using **exactly the same spatial layout as `StrokePaths.swift`**.

### Layout (derived directly from `StrokePaths.swift` lines 19–28)

For a 64×64 canvas:

```
Canvas size: C = 64px

Left character (main kana, e.g. き):
  rendered_size = C × 0.55 = 35.2px  → scale ETL image to 35×35
  x_origin = 0
  y_origin = (C − rendered_size) / 2 = 14.4px  → paste at y=14

Right character (small kana, e.g. ゃ):
  rendered_size = C × 0.40 = 25.6px  → scale ETL image to 26×26
  x_origin = left_size + (C − left_size − right_size) / 2 = 36.8px  → paste at x=37
  y_origin = (C − rendered_size) / 2 = 19.2px  → paste at y=19
```

This formula is the ground truth. `KanaRecognizer.swift` does not need to split anything at inference time — it renders the full canvas to 64×64 and classifies in a single forward pass.

### Sample generation

- Non-dakuten combinations (e.g. きゃ): left pool = ~120–240 ETL4/5 images, right pool = ~120–240 ETL4/5 images of full-size equivalent
- Dakuten combinations (e.g. ぎゃ): left pool = synthetic dakuten images (~120–240), right pool = ETL4/5 full-size equivalents
- Generate 300 composite images per combination class by sampling random pairs with replacement
- Apply augmentation to the full composite image (both components deform together)

---

## Augmentation

Applied on-the-fly during training to all images (single and combination). Key transforms:

| Transform | Parameters | Rationale |
|---|---|---|
| Rotation | ±15° | Touchscreen handwriting is not perfectly upright |
| Elastic distortion | α=80, σ=6 | Models natural stroke curve variation |
| Morphological dilation/erosion | kernel 1–2px, p=0.4 | Simulates stroke width variation from finger pressure |
| Scale jitter | ±10% | Drawing size varies by user |
| Perspective warp | ±5% | Canvas tilt / touch angle |
| Gaussian noise | σ≤0.02 | Sensor noise |
| **No horizontal flip** | — | Kana have handedness; flipped characters are wrong answers |

---

## Model Architecture

Small CNN with Global Average Pooling. Compact enough for Neural Engine inference in <5ms.

```
Input:  (1, 64, 64)  — single-channel grayscale, float32, values in [0, 1]

Block 1: Conv2d(1→32, 3×3, pad=1) → BN → ReLU → MaxPool(2×2)    → (32, 32, 32)
Block 2: Conv2d(32→64, 3×3, pad=1) → BN → ReLU → MaxPool(2×2)   → (64, 16, 16)
Block 3: Conv2d(64→128, 3×3, pad=1) → BN → ReLU → MaxPool(2×2)  → (128, 8, 8)
Block 4: Conv2d(128→256, 3×3, pad=1) → BN → ReLU → MaxPool(2×2) → (256, 4, 4)
         AdaptiveAvgPool2d(1)                                       → (256, 1, 1)

Head: Flatten → Linear(256→256) → ReLU → Dropout(0.4) → Linear(256→214) → Softmax
```

~3M parameters. ~12MB float32, ~6MB float16 when quantised. No quantisation required for initial ship.

---

## Preprocessing Contract

**This must match exactly between training (Python) and inference (Swift). This is the most common source of integration bugs.**

| Step | Training (Python) | Inference (Swift) |
|---|---|---|
| Canvas size | 64×64 px | 64×64 px |
| Background | White = 255 | White = UIColor.white fill |
| Stroke colour | Black = 0 | Black = UIColor.black stroke |
| Pixel range | [0, 255] uint8 | [0, 255] uint8 |
| Normalisation | divide by 255 → [0.0, 1.0] | divide by 255 → [0.0, 1.0] |
| Stroke width | ~2px (ETL stroke width at 64px scale) | `strokeWidth = 2.0pt` (scaled from DrawingCanvasView's 4pt at 260pt canvas) |
| Channel | Grayscale (1 channel) | Grayscale (1 channel) |
| Tensor shape | (1, 1, 64, 64) | MLMultiArray shape [1, 1, 64, 64] |

**Stroke width note:** `DrawingCanvasView` renders at `strokeWidth = 4pt` on a 260pt canvas. At inference, strokes are scaled by `64/260 ≈ 0.246`, so the effective rendered width is `4 × 0.246 ≈ 1pt`. Set `KanaRecognizer`'s render stroke width to `2.0pt` in the 64px canvas to approximate the visual density of ETL4/5 strokes at that scale. ETL4/5's 4-bit grayscale means stroke edges are softer than ETL8B's hard 1-bit edges — the rendered inference image (binary black strokes on white) is inherently harder-edged, but augmentation (including slight Gaussian blur) closes this gap.

---

## Training Configuration

```
Optimizer:     Adam, lr=1e-3
Scheduler:     CosineAnnealingLR, T_max=60 epochs
Loss:          CrossEntropyLoss
Batch size:    128
Max epochs:    60
Early stop:    patience=10 on val loss

Splits (all stratified per class):
  Main kana (ETL4/5):   80% train / 10% val / 10% test  (~96–333 / 12–42 / 12–42 per class)
  Dakuten (synthetic):  80% train / 10% val / 10% test  (inherits base class counts)
  Combination:          240 train / 30 val / 30 test     (from 300 generated per class)
```

Accuracy target: ≥95% top-1 on the held-out test set.

---

## File Structure

```
ml/
├── data/
│   ├── raw/
│   │   ├── etl4/            # ← place downloaded ETL4 files here (gitignored)
│   │   └── etl5/            # ← place downloaded ETL5 files here (gitignored)
│   └── processed/           # ← generated by pipeline scripts (gitignored)
│       ├── single/          # {char_unicode}/NNNN.png
│       └── combinations/    # {char1char2}/NNNN.png
├── models/
│   ├── kana_classifier.pth          # PyTorch checkpoint (gitignored)
│   ├── KanaClassifier.mlmodel       # committed — required for iOS build
│   ├── kana_labels.json             # committed — class index → character string
│   ├── confusion_matrix.png         # generated by evaluate.py (gitignored)
│   └── preprocessing_contract.md   # this document's preprocessing table
├── scripts/
│   ├── labels.py            # canonical label list (imported by all scripts)
│   ├── build_dakuten.py     # ETL4/5 base + overlaid ゛/゜ mark → dakuten PNGs
│   ├── build_combinations.py # composite two source images → combination PNGs
│   ├── augmentation.py      # albumentations pipeline
│   ├── dataset.py           # PyTorch Dataset
│   ├── model.py             # CNN architecture
│   ├── train.py             # training loop
│   ├── evaluate.py          # test-set accuracy + confusion matrix
│   └── convert_to_coreml.py # torch.jit.trace → .mlmodel
├── requirements.txt
└── README.md

KanaFlow/KanaFlow/
├── Logic/
│   └── KanaRecognizer.swift          # NEW — Core ML inference service
├── Models/
│   ├── KanaClassifier.mlmodel        # NEW — bundled from ml/models/
│   └── kana_labels.json              # NEW — bundled from ml/models/
└── Views/Quiz/
    └── GradingOverlayView.swift      # MODIFIED — use mlScore: Float? instead of StrokeScores
```

---

## iOS Changes

### Files to delete / retire
- `StrokeRecognition.swift` — DTW approach, dead end. **Delete after confirming nothing else imports it.**

### Files to modify

**`KanaFlow/ViewModels/QuizViewModel.swift`**
- Add `var mlScore: Float? = nil`
- Add `var mlGradeSubmitted: Bool = false`
- Change `submitDrawing(_ strokes:)` → `submitDrawing(_ strokes:, character:, canvasSize:)`
  - Call `KanaRecognizer.shared.score(...)` synchronously (Neural Engine latency < 5ms for this model)
  - If score returned: record result immediately (`store.updateProgress`, `results.append`), set `mlGradeSubmitted = true`, set `mlScore`, transition to `.selfGrading`
  - If nil: transition to `.selfGrading` without setting `mlGradeSubmitted` (fallback to manual self-grade)
- Add `continueAfterGrading(_ wasCorrect: Bool, store:)`:
  - If `mlGradeSubmitted`: call `nextQuestion()` (ignore `wasCorrect` — grade already recorded)
  - Else: call `submitSelfGrade(wasCorrect, store:)` (manual self-grade flow)
- Update `nextQuestion()` to reset `mlScore = nil` and `mlGradeSubmitted = false`

**`KanaFlow/Views/Quiz/QuizPlayView.swift`**
- Fix `selfGradingView` to use `GradingOverlayView` (not the non-existent `SelfGradeOverlayView`) — this fixes the current compile error
- Pass `vm.mlScore` as the `mlScore` parameter
- Update `onContinue` to call `vm.continueAfterGrading(wasCorrect, store: store)`
- Update `typeBView.onSubmit` to call `vm.submitDrawing(strokes, character: char, canvasSize: 260)`

**`KanaFlow/Views/Quiz/GradingOverlayView.swift`**
- Replace `let scores: StrokeScores?` with `let mlScore: Float?`
- Remove `drawingCanvasSize` parameter (no longer needed for scoring)
- Update `effectivePassed`: `(mlScore ?? 0) >= 0.65 && !hintUsed`
- Replace 4-bar `scoreSection` with single `mlScoreSection` showing "Legibility: 87%" bar
- Update `continueButton` to call `onContinue(effectivePassed)` (was `onContinue(s.passed)`)
- Self-grade fallback buttons remain unchanged (shown when `mlScore == nil`)

### New file

**`KanaFlow/Logic/KanaRecognizer.swift`**

```swift
final class KanaRecognizer {
    static let shared = KanaRecognizer()

    // Returns probability [0,1] that strokes represent targetCharacter.
    // Returns nil if model is unavailable or character not in label set.
    func score(strokes: [Stroke], canvasSize: CGFloat, targetCharacter: String) -> Float?
}
```

Internals:
1. Load `KanaClassifier.mlmodelc` from bundle via `MLModel(contentsOf:)` — returns nil gracefully if not present
2. Load `kana_labels.json` from bundle into `[String]` and build reverse `[String: Int]` index
3. `score()`: render strokes to 64×64 grayscale `CGImage` via `UIGraphicsImageRenderer`, convert to `MLMultiArray` (float32, normalised to [0,1]), run inference, return `Float(probabilities[classIdx])`

The model is loaded once at app launch via the `shared` singleton. No thread safety concern: `MLModel.prediction` is thread-safe, and `QuizViewModel.submitDrawing` runs on `@MainActor`.

---

## Phased Delivery

### Phase A — Python pipeline (no iOS changes)
1. ~~`parse_etl.py`~~ — **already done** (ETL4/5 pre-processed to PNG by user)
2. `build_dakuten.py` — overlay ゛/゜ marks onto ETL4/5 base images to generate 50 dakuten classes
3. `build_combinations.py` — composite combination images from ETL4/5 + synthetic dakuten sources
3. `augmentation.py`, `dataset.py`, `model.py` — training infrastructure
4. `train.py` — training loop, checkpoint save
5. `evaluate.py` — test-set accuracy, confusion matrix

**Gate:** ≥95% top-1 accuracy on test set before proceeding.

### Phase B — Core ML conversion
6. `convert_to_coreml.py` — trace, convert, embed labels in metadata, save `.mlmodel`
7. Copy `KanaClassifier.mlmodel` + `kana_labels.json` into `KanaFlow/KanaFlow/Models/`
8. Commit both files

### Phase C — iOS integration
9. `KanaRecognizer.swift` — inference service
10. Update `GradingOverlayView.swift` — use `mlScore: Float?`
11. Update `QuizViewModel.swift` — call `KanaRecognizer`, add `continueAfterGrading`
12. Update `QuizPlayView.swift` — fix compile error, wire new API
13. Delete `StrokeRecognition.swift`
14. Regenerate Xcode project with `xcodegen generate`
15. Build and test on device

---

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Preprocessing mismatch between training and inference | `preprocessing_contract.md` documents every step; `parse_etl.py` includes a visual spot-check that saves 10 random samples as PNGs for manual inspection before training |
| Dakuten mark placement wrong for some characters | Spot-check synthesised dakuten PNGs visually before training; adjust per-character mark offset table in `build_dakuten.py` if needed |
| Training/inference domain gap (grayscale ETL vs binary rendered strokes) | Add slight Gaussian blur to augmentation pipeline to soften inference-side hard edges; monitor per-class accuracy — if certain characters underperform, increase augmentation variance |
| Combination image quality | Spot-check 20 random combination composites; confirm left/right positioning matches the app's hint stroke overlay visually |
| Sub-95% accuracy | With ~5000 samples/class and 4-bit grayscale, this is unlikely. If it occurs: increase augmentation strength or add a 5th conv block |
| Model too large | Quantise to float16 with `coremltools` — expected ~6MB, well within budget |
| iOS build fails without `.mlmodel` | `KanaRecognizer` uses `MLModel(contentsOf:)` with optional chaining — returns nil and falls back to self-grading if model not present |
