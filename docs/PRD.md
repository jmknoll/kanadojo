# Kana Flow Product Requirements Document

## Feature Development Workflow

For every new feature request, before writing any code:

1. **Update this PRD** — add the feature to the relevant section and append a task checklist under the appropriate phase
2. **Create an implementation plan** in `docs/<feature-name>-plan.md` — files to change, step-by-step approach, edge cases

## Overview

Kana Flow is a mobile app for learning Japanese kana (hiragana and katakana) through interactive quizzes. The app focuses on active recall and spaced repetition to help users memorize all 46 basic characters plus their variations.

## Target Users

- Japanese language beginners
- Self-study learners preparing for JLPT N5
- Anyone wanting to refresh their kana knowledge

---

## Core Features

### 1. Top-Level Navigation

Two primary modes:

- **Study Mode** (Phase 2) - Reference charts and learning materials
- **Quiz Mode** (Phase 1) - Active recall testing

### 2. Quiz Flow

#### 2.1 Kana Type Selection

- Hiragana (ひらがな)
- Katakana (カタカナ)
- Mixed (both) - future enhancement

#### 2.2 Subsection Selection

| Subsection         | Description                            | Count |
| ------------------ | -------------------------------------- | ----- |
| All                | All characters                         | 46+   |
| Main (Gojūon)      | Basic characters (あ-ん)               | 46    |
| Dakuten            | Voiced consonants (が, ざ, だ, ば, ぱ) | 25    |
| Combination (Yōon) | Combined sounds (きゃ, しゅ, ちょ)     | 36    |

#### 2.2.1 Row Selection (optional)

After selecting a subsection, users may optionally narrow the quiz to specific rows within that subsection. This appears on the quiz configuration screen as a collapsible multi-select section.

- **Default**: All rows in the selected subsection (no row filter applied)
- **Selection**: User can toggle individual rows on/off (e.g., select only "a-row" and "ka-row" from Main)
- **Row labels**: Displayed as the row's romaji root (e.g., "a", "ka", "sa", "ga", "kya")
- **Dynamic**: Available rows update automatically when Kana Type or Character Group changes; any active row selection resets on group/type change
- **Availability**: Only rows that actually contain characters in the current selection are shown
- **Summary**: The question count summary reflects the filtered character pool

**Example rows by group:**

| Group       | Rows |
| ----------- | ---- |
| Main        | a, ka, sa, ta, na, ha, ma, ya, ra, wa, n |
| Dakuten     | ga, za, da, ba, pa |
| Combination | kya, sha, cha, nya, hya, mya, rya, gya, ja, dya, bya, pya |

#### 2.3 Quiz Types

**Type A: Kana → Romaji (Recognition)**

- Display: Kana character on card
- Input: User types romaji answer
- Validation: Exact match (with common alternatives accepted, e.g., "si"/"shi")

**Type B: Romaji → Kana (Production/Handwriting)**

- Display: Romaji text
- Input: User draws kana on canvas
- Validation: Handwriting recognition (see Technical Considerations)
- Hints: Show stroke order, first stroke, or ghost outline

### 3. Progress Tracking & Spaced Repetition

#### 3.1 Performance Metrics (per character)

- Correct/incorrect counts
- Success rate percentage
- Last practiced timestamp
- Current "level" (new → learning → reviewing → mastered)

#### 3.2 Spaced Repetition Logic

- Characters answered incorrectly appear more frequently
- Mastered characters appear less often
- Progress tracked separately for:
  - Hiragana vs Katakana
  - Quiz Type A vs Quiz Type B

#### 3.3 Weak Character Quiz Mode

- "Practice Weak Characters" option
- Filters to characters with <70% success rate
- Prioritizes least recently practiced

---

## Technical Considerations

### Handwriting Recognition

**Chosen approach: On-device CNN classifier via Core ML.**

A small CNN is trained on the ETL Character Database (AIST) and converted to Core ML. At inference time, the user's strokes are rendered to a 64×64 grayscale bitmap and classified against all 214 character classes. The probability assigned to the correct class is the legibility score — a well-formed character scores high regardless of stroke order, while a garbled one scores low.

The earlier DTW (stroke-matching) approach in `StrokeRecognition.swift` is retired. It measured geometric path fidelity rather than legibility and produced unreliable scores.

See full plan: [docs/ml-handwriting-recognition-plan.md](ml-handwriting-recognition-plan.md)

**Previous approaches considered:**

| Approach | Status |
| --- | --- |
| ML Model (Core ML) | ✅ **Selected** |
| Cloud API (Google Vision) | Rejected — requires network, cost |
| DTW Stroke Matching | ❌ Retired — measures path fidelity, not legibility |
| Self-Grading | Fallback only — shown when ML model unavailable |

### Hint System for Handwriting

- **Stroke Order Animation**: Show how to draw the character
- **First Stroke Hint**: Display only the starting stroke
- **Ghost Outline**: Faint character underneath canvas
- **Stroke Count**: Show expected number of strokes

### Data Storage

- Local storage (UserDefaults) for offline-first experience
- Optional cloud sync via iCloud/CloudKit (future enhancement)

---

## Phases & Tasks

### Phase 1: Quiz Foundation (MVP)

**1.1 Data Layer** ✅

- [x] Create kana data structure (character, romaji, type, group)
- [x] Implement complete hiragana dataset (main, dakuten, combination)
- [x] Implement complete katakana dataset
- [x] Set up local storage for progress tracking

**1.2 Navigation & Screens** ✅

- [x] Home screen with Study/Quiz options
- [x] Kana type selection screen (hiragana/katakana)
- [x] Subsection selection screen (all/main/dakuten/combination)
- [x] Quiz type selection screen

**1.5 Row Selection Filter**

- [ ] Add `selectedRows` to `QuizConfig` (empty = all rows)
- [ ] Add `getAvailableRows` helper to `KanaData` returning ordered, deduplicated row keys for a given type+group
- [ ] Update `KanaData.getCharacters` to accept and apply optional row filter
- [ ] Update `QuizSetupViewModel` with `selectedRows` state, reset on type/group change, propagate to `config`
- [ ] Create `RowSelectorView` — collapsible multi-select chip list below Character Group
- [ ] Wire `RowSelectorView` into `QuizSetupView`
- [ ] Apply row filter in `QuizViewModel.load` and `ProgressStore.getStrugglingIds`

**1.3 Quiz Type A: Kana → Romaji** ✅

- [x] Quiz card component displaying kana
- [x] Text input for romaji answer
- [x] Answer validation logic (handle alternate romanizations)
- [x] Correct/incorrect feedback UI — inline highlight (green/red border + background tint); auto-advance on correct; correction text on incorrect. No full-screen overlay.
- [x] Quiz completion summary screen

**1.4 Basic Progress Tracking** ✅

- [x] Track correct/incorrect per character
- [x] Persist progress to local storage
- [x] Display success rate on completion screen

### Phase 2: Handwriting Quiz ✅

**2.1 Drawing Canvas** ✅

- [x] Implement touch drawing canvas
- [x] Stroke capture and rendering
- [x] Clear/undo functionality

**2.2 Self-Grading Flow** ✅

- [x] Show correct answer after submission (side-by-side drawing vs. correct kana)
- [x] "Correct" / "Incorrect" self-assessment buttons
- [x] Track results same as Type A (saved to `quizTypeB` in UserDefaults)
- [x] Skip redundant feedback screen — advance directly to next question after self-grade
- [x] Canvas clears between characters

**2.3 Hint System** ✅

- [x] Stroke order data for 158 individual kana sourced from KanjiVG (covers all 214 quiz characters including combinations via path concatenation)
- [x] "Hint" button on canvas toolbar — reveals next stroke in red each press, animated fade-in
- [x] Button label shows progress: "Hint (2/3)"; disabled after all strokes revealed
- [x] Hint strokes render as red semi-transparent paths under user's drawing (scaled from KanjiVG 109×109 coordinate space)
- [x] Any hint use forces the question to count as incorrect (regardless of self-grade)
- [x] Self-grade overlay shows "Hints used — counted as incorrect" notice when applicable

### Phase 3: Spaced Repetition

**3.1 Algorithm Implementation**

- [ ] Calculate character "strength" based on history
- [ ] Implement review scheduling (SM-2 variant or custom)
- [ ] Separate tracking: hiragana/katakana × quiz type

**3.2 Weak Character Mode**

- [ ] Filter characters by success rate threshold
- [ ] Sort by weakness score
- [ ] "Practice Weak Characters" quiz option

**3.3 Progress Dashboard**

- [ ] Overall progress visualization
- [ ] Per-character breakdown
- [ ] Streak tracking

### Phase 4: Study Mode

**4.1 Reference Charts**

- [x] Hiragana chart screen
- [x] Katakana chart screen
- [x] Tap character for details (stroke order, romaji pronunciation)

### Phase 5: ML Handwriting Recognition

See full plan: [docs/ml-handwriting-recognition-plan.md](ml-handwriting-recognition-plan.md)

**Note:** The DTW stroke-matching approach (`StrokeRecognition.swift`) is retired. `GradingOverlayView.swift` exists but was never wired to the quiz flow. `QuizPlayView.swift` references the non-existent `SelfGradeOverlayView`, causing a compile error. This phase fixes all of the above.

**5.A Python Pipeline**

- [x] ETL4/5 pre-processed to PNG by user (72×76px grayscale, hex-codepoint directories, `.char.txt` identity files) — covers 92 main kana classes
- [ ] `build_dakuten.py` — overlay rendered ゛/゜ marks onto ETL4/5 base images to synthesise all 50 dakuten classes; one image per base sample with per-sample mark jitter
- [ ] `build_combinations.py` — composite left + right component images into 64×64 canvas using StrokePaths layout (left at 55%, right at 40%); generate 300 images per combination class; right component uses full-size ETL4/5 equivalent scaled down by compositing
- [ ] `augmentation.py` — elastic distortion, rotation ±15°, morphological stroke-width variation, scale jitter, perspective warp
- [ ] `dataset.py` — PyTorch Dataset over processed PNGs with on-the-fly augmentation
- [ ] `model.py` — 4-block CNN with GlobalAvgPool → 214 softmax classes (~3M params)
- [ ] `train.py` — Adam + CosineAnnealingLR, 60 epochs, checkpoint on best val loss
- [ ] `evaluate.py` — top-1 accuracy + per-class breakdown + confusion matrix PNG

**Gate: ≥95% test-set accuracy before proceeding to Phase 5.B**

**5.B Core ML Conversion**

- [ ] `convert_to_coreml.py` — `torch.jit.trace` → `coremltools.convert` → `.mlmodel` with softmax output, labels embedded in `userDefinedMetadata`
- [ ] Commit `KanaClassifier.mlmodel` + `kana_labels.json` to `KanaFlow/KanaFlow/Models/`

**5.C iOS Integration**

- [ ] `KanaRecognizer.swift` — singleton service; renders strokes to 64×64 bitmap via `UIGraphicsImageRenderer`; loads `KanaClassifier.mlmodelc` via `MLModel(contentsOf:)`; returns `Float?` probability for target class
- [ ] Update `GradingOverlayView.swift` — replace `StrokeScores?` with `mlScore: Float?`; single legibility bar instead of 4 sub-score bars
- [ ] Update `QuizViewModel.swift` — `submitDrawing` calls `KanaRecognizer`, records grade, sets `mlGradeSubmitted`; add `continueAfterGrading(wasCorrect:store:)`
- [ ] Update `QuizPlayView.swift` — fix compile error (use `GradingOverlayView` not `SelfGradeOverlayView`); wire `continueAfterGrading`
- [ ] Delete `StrokeRecognition.swift`
- [ ] Run `xcodegen generate`, build and test on device

**5.D Stats Page Overhaul** *(deferred — does not block 5.C ship)*

- [ ] Add kana type filter (All / Hiragana / Katakana) to `StatsView`
- [ ] Add expandable character browser by mastery level (tappable grid → CharacterDetailView)
- [ ] Add per-character legibility score history to `CharacterProgress` (SchemaV3 migration)
- [ ] Create `SpiderChartView` (legibility trend chart in `CharacterDetailView`)

### Phase 6: Polish & Enhancements

**6.0 Notifications**

- [ ] Add settings page with ability to enable/disable notifications
- [ ] Add daily reminder push notification
- [ ] On first open, add notification permission popup (with text about the importance of daily reminders)

**6.1 UX Improvements**

- [ ] Animations and transitions
- [ ] Sound effects
- [x] Dark mode support
- [ ] Haptic feedback
- [ ] Some improved version of stroke order in study mode

**6.3 Gamification**

- [ ] Daily goals
- [ ] Achievements/badges
- [ ] Streak rewards

---

## Kana Reference Data

### Hiragana Groups

**Main (Gojūon) - 46 characters:**

```
あ(a)  い(i)  う(u)  え(e)  お(o)
か(ka) き(ki) く(ku) け(ke) こ(ko)
さ(sa) し(shi) す(su) せ(se) そ(so)
た(ta) ち(chi) つ(tsu) て(te) と(to)
な(na) に(ni) ぬ(nu) ね(ne) の(no)
は(ha) ひ(hi) ふ(fu) へ(he) ほ(ho)
ま(ma) み(mi) む(mu) め(me) も(mo)
や(ya)        ゆ(yu)        よ(yo)
ら(ra) り(ri) る(ru) れ(re) ろ(ro)
わ(wa)                      を(wo)
ん(n)
```

**Dakuten - 25 characters:**

```
が(ga) ぎ(gi) ぐ(gu) げ(ge) ご(go)
ざ(za) じ(ji) ず(zu) ぜ(ze) ぞ(zo)
だ(da) ぢ(ji) づ(zu) で(de) ど(do)
ば(ba) び(bi) ぶ(bu) べ(be) ぼ(bo)
ぱ(pa) ぴ(pi) ぷ(pu) ぺ(pe) ぽ(po)
```

**Combination (Yōon) - 36 characters:**

```
きゃ(kya) きゅ(kyu) きょ(kyo)
しゃ(sha) しゅ(shu) しょ(sho)
ちゃ(cha) ちゅ(chu) ちょ(cho)
にゃ(nya) にゅ(nyu) にょ(nyo)
ひゃ(hya) ひゅ(hyu) ひょ(hyo)
みゃ(mya) みゅ(myu) みょ(myo)
りゃ(rya) りゅ(ryu) りょ(ryo)
ぎゃ(gya) ぎゅ(gyu) ぎょ(gyo)
じゃ(ja)  じゅ(ju)  じょ(jo)
びゃ(bya) びゅ(byu) びょ(byo)
ぴゃ(pya) ぴゅ(pyu) ぴょ(pyo)
```

---

## Success Metrics

- User can complete a full quiz session without confusion
- Progress persists between app sessions
- Handwriting input feels responsive (<100ms latency)
- Users show improvement in weak characters over time

---

## Open Questions

1. Should mixed hiragana/katakana mode be in Phase 1 or later?
2. Audio pronunciation - priority level?
3. Offline-only or cloud sync from start?
4. Monetization model (if any)?
