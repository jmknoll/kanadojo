# Kana Recognition ML Implementation Plan

## Overview

Replace the existing self-grading overlay with an ML-based automatic scoring system. The user's drawn strokes are evaluated by a `KanaRecognizer` model, and the result (correct/incorrect) is determined automatically — no manual grading buttons.

---

## Phases

### Phase 1–4 (unchanged)

Core ML model integration, stroke preprocessing, and canvas data pipeline. See prior planning notes.

---

### Phase 5 — Full ML Integration (replaces self-grading)

**Files changed/replaced:**

| File | Change |
|------|--------|
| `KanaFlow/Logic/KanaRecognizer.swift` | New — wraps Core ML model, exposes `score(strokes:canvasSize:targetClass:) async -> Float` |
| `KanaFlow/ViewModels/QuizViewModel.swift` | Modified — calls `KanaRecognizer`, drives result state |
| `KanaFlow/Views/Quiz/SelfGradeOverlayView.swift` | Replaced by `MLScoreResultView` |
| `KanaFlow/Views/Quiz/DrawingCanvasView.swift` | Minor — remove hint-penalty logic |

**New quiz flow:**

1. User submits strokes via the "Submit" button in `DrawingCanvasView`
2. `QuizViewModel` calls `KanaRecognizer.score(strokes:canvasSize:targetClass:)` (async)
3. A brief "Scoring…" state is shown while inference runs
4. The returned `Float` (0–1) determines the result:
   - `≥ 0.5` → marked **correct**
   - `< 0.5` → marked **incorrect**
   - Raw score is shown as a legibility indicator (e.g. "Score: 87%")
5. `MLScoreResultView` displays:
   - The user's drawing
   - The correct character
   - The numeric score
   - A ✓ / ✗ verdict
   - **No manual grading buttons**

**Removed behaviour:**

- `SelfGradeOverlayView` and its "Got it right / Got it wrong" buttons are fully removed
- The hint penalty (hints used → forced incorrect) is removed; the ML score naturally degrades for poorly-formed characters

---

### Phase 6 (unchanged)

Progress persistence, spaced-repetition integration, and optional threshold tuning UI.

---

## Pass/Fail Threshold

The initial threshold is **0.5**. The raw score is stored on `CharacterProgress` to allow future threshold tuning without re-running inference.

---

## Notes

- The ML approach fully replaces the existing self-grading implementation — there is no hybrid mode
- Threshold can be surfaced as a user-facing setting in a follow-on PR if needed
