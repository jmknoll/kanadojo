# Handwriting Recognition — Implementation Plan

## Overview

This plan covers the full implementation of automated handwriting grading for Type B (Romaji → Kana) quizzes, replacing the current self-grading flow, plus the corresponding stats page overhaul described in `handwriting-system.md`.

The work is divided into four sequential phases. Each phase is independently shippable.

---

## Phase 1 — Recognition Engine

### 1.1 What It Does

Given a user's drawn strokes (`[[CGPoint]]`) and the KanjiVG reference strokes for the same character, it produces four sub-scores (each 0.0–1.0) and a weighted overall grade.

| Score            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| **Shape**        | How closely each drawn stroke's path matches the reference                |
| **Proportion**   | Whether stroke lengths are in the right relative proportions              |
| **Stroke Order** | Fraction of strokes drawn in the canonical order                          |
| **Consistency**  | How stable the user's shape score is across repeated attempts (EMA-based) |

Overall grade formula:

```
grade = 0.50 × shape + 0.3 × proportion + 0.2 × stroke_order
```

Passing threshold: `grade >= 0.65`

Consistency is computed separately (not part of the in-quiz grade) and stored for the stats spider chart.

### 1.2 New File: `KanaFlow/Logic/StrokeRecognition.swift`

#### Coordinate spaces

- **Reference space**: KanjiVG paths live in a 109×109 grid. Normalise by dividing by 109 → [0,1]².
- **User space**: Raw canvas CGPoints in [0, canvasSize]². Normalise by dividing by canvasSize → [0,1]².
- All comparisons happen in normalised [0,1]² space.

#### Extracting reference point sequences

`StrokeOrder.swift` stores SVG path strings. `SVGPathParser.swift` already converts these to SwiftUI `Path` objects. We need a parallel path that produces `[[CGPoint]]`.

Add `referenceStrokes(for character: KanaCharacter) -> [[CGPoint]]`:

- Parse the raw SVG path strings from `StrokeOrder.strokeData[character.character]` using a lightweight point-sampler (walk M/L/C/Q commands, sample every ~2pt along the path, scale by `1/109`).
- For combination kana (two-character strings), tile left/right at 55%/40% the same way `StrokePaths.strokePaths(for:in:)` does, but in [0,1]² normalised space.
- Cache results in a `[String: [[CGPoint]]]` dictionary (computed once at app start or first use per character, not per quiz question).

#### Resampling

Both user strokes and reference strokes are resampled to exactly **N = 64 points** using linear interpolation along cumulative arc length. This makes DTW O(64²) ≈ 4 096 operations per stroke pair — trivially fast.

```swift
func resample(_ stroke: [CGPoint], count: Int = 64) -> [CGPoint]
```

#### DTW

Standard O(n²) DTW with Euclidean point distance. Returns the unnormalised distance.

```swift
func dtw(_ a: [CGPoint], _ b: [CGPoint]) -> Double
```

Normalise by dividing by `Double(N)` so the result is a per-point average distance in [0,1]² space.

#### Shape score

For a single matched pair (user stroke u, reference stroke r):

```
stroke_shape = max(0, 1 - dtw(resample(u), resample(r)) / normalisationConstant)
```

`normalisationConstant = 0.3` (empirically: a stroke that deviates by an average of 0.3 units per point across the unit square is clearly wrong).

Overall shape score = mean stroke_shape across all matched pairs.

#### Stroke matching (greedy nearest-match)

Given U user strokes and R reference strokes:

1. Build a U×R distance matrix using DTW.
2. Greedy: repeatedly pick the smallest-distance (u,r) pair, assign it, and remove both u and r from the pool.
3. If `|U| < |R|`: unmatched reference strokes contribute score 0 to shape.
4. If `|U| > |R|`: extra user strokes are ignored (already penalised by proportion score).
5. Record the assignment order to compute stroke order score.

For typical kana (1–5 strokes), this is O(R² × 64²) — negligible.

#### Stroke order score

Let `assigned_pairs = [(u_idx, r_idx)]` sorted by `u_idx` (draw order).

```
in_order_count = count of pairs where extracted r_idx sequence is strictly increasing
stroke_order_score = in_order_count / total_pairs
```

If only one stroke, stroke_order_score = 1.0.

#### Proportion score

For each matched pair, compare the user stroke length to the reference stroke length, both expressed as fractions of their respective totals.

```
ref_fractions[i] = len(ref[i]) / sum(len(ref))
usr_fractions[j] = len(usr[j]) / sum(len(usr))
deviation[k] = |ref_fractions[matched_r] - usr_fractions[matched_u]|
proportion_score = max(0, 1 - mean(deviation) / 0.25)
```

`0.25` = normalisation constant (25% average fractional deviation = score 0).

#### Consistency score

Stored as a field in `CharacterProgress` (see Phase 2). Updated after each attempt using an exponential moving average (α = 0.3) of the shape score:

```
newEMA = 0.3 × latestShapeScore + 0.7 × previousEMA
consistency = 1 - |latestShapeScore - newEMA|
```

On the first attempt, EMA = latestShapeScore, consistency = 1.0 (no variance yet).

#### Public API

```swift
struct StrokeScores {
    let shape: Double          // 0–1
    let proportion: Double     // 0–1
    let strokeOrder: Double    // 0–1
    let consistency: Double    // 0–1 (requires prior EMA from CharacterProgress)
    let overall: Double        // weighted grade
    let passed: Bool           // overall >= 0.65
}

func gradeDrawing(
    userStrokes: [[CGPoint]],
    character: KanaCharacter,
    priorShapeEMA: Double      // from CharacterProgress.typeBShapeEMA
) -> StrokeScores
```

---

## Phase 2 — Data Model

### 2.1 New fields on `CharacterProgress`

Add the following `@Attribute` fields. All are `Double`, default 0.0, except `typeBAttemptCount` which is `Int`.

```swift
var typeBShapeEMA: Double = 0.0          // EMA of shape score across attempts
var typeBLatestShape: Double = 0.0       // most recent shape score
var typeBLatestProportion: Double = 0.0  // most recent proportion score
var typeBLatestStrokeOrder: Double = 0.0 // most recent stroke order score
var typeBLatestConsistency: Double = 0.0 // most recent consistency score
var typeBLatestOverall: Double = 0.0     // most recent overall grade
```

The "latest" fields are used for the spider chart on CharacterDetailView. The EMA field persists across sessions for consistency tracking.

No `typeA` metric fields are added now (the doc describes typeA metrics as optional/future).

### 2.2 Schema migration

Add `SchemaV3` to `AppMigrationPlan.swift`:

```swift
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] { [CharacterProgress.self] }
}

static let migrateV2toV3 = MigrationStage.lightweight(
    fromVersion: SchemaV2.self,
    toVersion: SchemaV3.self
)
```

Lightweight migration is sufficient: all new fields have `0.0` defaults, which is appropriate (no prior data).

Update `AppMigrationPlan.schemas` and `.stages` to include `SchemaV3` and `migrateV2toV3`.

---

## Phase 3 — Quiz Flow Changes

### 3.1 QuizViewModel

Replace the `submitSelfGrade` flow with `submitGradedDrawing`.

#### New state in QuizViewModel

```swift
var pendingScores: StrokeScores? = nil
```

#### New flow

```
submitDrawing(strokes)
  → run gradeDrawing() synchronously (it's fast enough — a few ms per question)
  → store result in pendingScores
  → if hint was used, force passed = false (same as today)
  → transition to .selfGrading state (now renamed .grading)
```

```
confirmGrade()  // replaces submitSelfGrade(correct:)
  → update CharacterProgress:
      typeBShapeEMA = 0.3 × pendingScores.shape + 0.7 × old
      typeBLatest* = pendingScores.*
      if pendingScores.passed: typeBCorrect++ + applySpacedRepetition(correct: true)
      else: typeBIncorrect++ + applySpacedRepetition(correct: false)
  → clear pendingScores
  → advance to next question
```

The spaced repetition algorithm (`applySpacedRepetition`) remains binary (correct/incorrect) for now. In a future enhancement, the overall grade could replace the binary signal for more granular SM-2 adjustments.

### 3.2 Replace `SelfGradeOverlayView` with `GradingOverlayView`

**New file:** `KanaFlow/Views/Quiz/GradingOverlayView.swift`

Layout:

```
┌─────────────────────────────────────┐
│  [Your drawing]    [Reference char] │  ← same side-by-side as today
├─────────────────────────────────────┤
│  ✓ / ✗  Overall: 78%               │  ← pass/fail badge + overall score
│                                     │
│  Shape       ████████░░  82%        │  ← horizontal bar per metric
│  Proportion  ███████░░░  74%        │
│  Stroke Order ██████░░░░  65%       │
│  Consistency ████████░░  80%        │
│                                     │
│  ⚠ Hint used — counted as incorrect │  ← if applicable
│                                     │
│          [ Continue ]               │
└─────────────────────────────────────┘
```

Props:

```swift
struct GradingOverlayView: View {
    let character: KanaCharacter
    let userStrokes: [[CGPoint]]   // already stored in QuizViewModel
    let scores: StrokeScores
    let hintUsed: Bool
    let onContinue: () -> Void
}
```

The "Continue" button calls `vm.confirmGrade()`.

`SelfGradeOverlayView.swift` can be deleted once `GradingOverlayView` is complete and wired up.

### 3.3 QuizPlayView changes

- In `selfGradingView(char:)`, replace `SelfGradeOverlayView(...)` with `GradingOverlayView(scores: vm.pendingScores!, ...)`.
- Remove `onCorrect`/`onIncorrect` callbacks; replace with `onContinue: { vm.confirmGrade() }`.

---

## Phase 4 — Stats Page Overhaul

### 4.1 Kana type filter in StatsView

Add `@State private var selectedKanaType: KanaType? = nil` (nil = All).

Add a segmented picker row above the existing quiz type picker:

```
[ All ] [ Hiragana ] [ Katakana ]
```

Filter `allProgress` by kana type using `KanaData.allCharacters` as the lookup:

```swift
private var filteredProgress: [CharacterProgress] {
    guard let kt = selectedKanaType else { return allProgress }
    let ids = Set(KanaData.allCharacters.filter { $0.type.rawValue == kt.rawValue }.map { $0.id })
    return allProgress.filter { ids.contains($0.characterId) }
}
```

All derived data (`practiced`, `overallAccuracy`, `masteryBreakdown`, `needsPractice`) already use `allProgress` — change them to use `filteredProgress`.

### 4.2 Character browser by mastery level

Replace (or follow) the "Mastery" section's bar chart with expandable character grids.

Each level (New, Learning, Reviewing, Mastered) shows:

- A header row: level name + count + chevron (expand/collapse)
- When expanded: a `LazyVGrid` of `ChipView`-style cells, each showing the kana character and romaji, tappable to navigate to `CharacterDetailView`

```swift
@State private var expandedLevels: Set<MasteryLevel> = []

private func characterBrowserSection(level: MasteryLevel) -> some View {
    let chars = charactersByLevel(level)  // [KanaCharacter]
    // ... expandable header + grid
}
```

Keep the existing bar chart above the browser as a visual summary.

New helper:

```swift
private func charactersByLevel(_ level: MasteryLevel) -> [KanaCharacter] {
    let charDict = Dictionary(uniqueKeysWithValues: KanaData.allCharacters.map { ($0.id, $0) })
    let progressByLevel: [CharacterProgress]
    switch selectedType {
    case .typeA: progressByLevel = filteredProgress.filter { $0.typeAMasteryLevel == level }
    case .typeB: progressByLevel = filteredProgress.filter { $0.typeBMasteryLevel == level }
    }
    return progressByLevel.compactMap { charDict[$0.characterId] }
}
```

For "New" characters (no progress record yet), compute them as `allFilteredCharacters - characterized`.

### 4.3 Spider chart in CharacterDetailView

**New file:** `KanaFlow/Views/Stats/SpiderChartView.swift`

A SwiftUI `Canvas`-drawn radar chart with 4 axes (or 5 if consistency is present):

```
         shape
          ↑
          │
stroke ───┼─── proportion
order     │
          ↓
       consistency
```

Axes are evenly spaced in angle. Each axis renders a label and a polygon vertex at `radius × score`. The filled polygon is drawn with `AppColors.tint.opacity(0.3)`, the outline in `AppColors.tint`.

```swift
struct SpiderChartView: View {
    struct Axis {
        let label: String
        let value: Double  // 0–1
    }
    let axes: [Axis]
    var size: CGFloat = 160
}
```

**In CharacterDetailView**, add a `typeBMetricsSection` between `strokeOrderSection` and `progressSection`:

Only shown when `typeBLatestOverall > 0` (i.e., at least one Type B attempt with graded data):

```swift
private var typeBMetricsSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.md) {
        Text("Production Quality")
            .font(AppFonts.heading3)
        SpiderChartView(axes: [
            .init(label: "Shape",        value: progress.typeBLatestShape),
            .init(label: "Proportion",   value: progress.typeBLatestProportion),
            .init(label: "Stroke Order", value: progress.typeBLatestStrokeOrder),
            .init(label: "Consistency",  value: progress.typeBLatestConsistency),
        ])
        .frame(maxWidth: .infinity)
    }
}
```

---

## Files Summary

| Action     | File                                                                        |
| ---------- | --------------------------------------------------------------------------- |
| **Create** | `KanaFlow/Logic/StrokeRecognition.swift`                                    |
| **Create** | `KanaFlow/Views/Quiz/GradingOverlayView.swift`                              |
| **Create** | `KanaFlow/Views/Stats/SpiderChartView.swift`                                |
| **Delete** | `KanaFlow/Views/Quiz/SelfGradeOverlayView.swift`                            |
| **Modify** | `KanaFlow/Data/CharacterProgress.swift` — add 6 new fields                  |
| **Modify** | `KanaFlow/Data/AppMigrationPlan.swift` — add SchemaV3                       |
| **Modify** | `KanaFlow/ViewModels/QuizViewModel.swift` — grading engine integration      |
| **Modify** | `KanaFlow/Views/Quiz/QuizPlayView.swift` — wire GradingOverlayView          |
| **Modify** | `KanaFlow/Views/Stats/StatsView.swift` — kana filter + character browser    |
| **Modify** | `KanaFlow/Views/Study/CharacterDetailView.swift` — add spider chart section |
| **Modify** | `project.yml` — register new files (xcodegen handles this automatically)    |

---

## Implementation Order

1. **Phase 1** (engine first): Build and unit-test `StrokeRecognition.swift` in isolation. Write a small test harness that calls `gradeDrawing` with hand-crafted strokes and logs the scores to the console. Tune normalisation constants.
2. **Phase 2** (data model): Add fields to `CharacterProgress`, add SchemaV3 migration, confirm simulator migration succeeds without data loss.
3. **Phase 3** (quiz flow): Build `GradingOverlayView`, integrate into `QuizViewModel` and `QuizPlayView`, delete `SelfGradeOverlayView`. At this point the end-to-end graded quiz is functional.
4. **Phase 4** (stats): Kana filter first (self-contained), then character browser, then `SpiderChartView` + CharacterDetailView integration.

---

## Open Questions

1. **Normalisation constants**: `0.3` for shape distance and `0.25` for proportion deviation are initial guesses. They should be tuned by testing against a range of drawn characters from different users. Consider exposing them as debug-only `UserDefaults` toggles during development.

Let's use these for now, and flag them in Claude.md so that future agents know to refine them as we debug.

2. **Combination kana tiling**: The left/right tiling logic in `StrokePaths.swift` uses `0.55 × size` for the main glyph and `0.40 × size` for the small one. The reference stroke extractor must replicate this exactly, or shape comparisons for combination characters will be systematically off.

Let's add a small buffer for combination characters so that we allow more variance in stroke position.

3. **Characters with no KanjiVG data**: `StrokeOrder.strokeData` may not cover every character (particularly obscure combinations). When reference strokes are unavailable, `gradeDrawing` should return `nil` and the quiz should fall back to the old self-grading flow for that question.

Please let me know which characters do not have references. I would expect that all characters have references in the dataset.

4. **SM-2 granularity**: The current SM-2 integration remains binary (pass/fail). A future enhancement could feed the continuous `overall` score into SM-2's ease factor directly (e.g., a score of 0.9 increases ease more than 0.7), giving finer-grained scheduling. Deferred to a separate plan.

Let's build this enhancement as part of the implementation.

5. **Speed/fluency metric**: Requires storing timestamps alongside CGPoints in `Stroke`. Currently `Stroke = [CGPoint]`. A future change would redefine `Stroke = [(point: CGPoint, time: TimeInterval)]`, which is a breaking change throughout `DrawingCanvasView`, `SelfGradeOverlayView` (→ `GradingOverlayView`), and `QuizViewModel`. Deferred.

Let's defer poitns 5 and 6 for now.

6. **Type A consistency/fluency**: The doc mentions Type A quizzes could also use weighted scoring (correctness dominant, plus consistency/fluency). Out of scope for this plan — Type A grading remains binary.
