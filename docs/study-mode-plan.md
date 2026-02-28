# Study Mode — Phase 4.1 Implementation Plan

## Overview

Build the Reference Charts feature: a browsable kana table with a character detail sheet showing stroke order. This enables the Study tile on the home screen.

---

## Navigation Changes

### 1. Add destinations to `AppDestination` (ContentView.swift)

```swift
enum AppDestination: Hashable {
    case quizSetup
    case quizPlay(config: QuizConfig)
    case study
    case characterDetail(character: KanaCharacter)
}
```

`KanaCharacter` is already `Hashable`, so no extra conformance needed.

### 2. Wire up destinations in `ContentView`

```swift
case .study:
    StudyView(path: $path)
case .characterDetail(let character):
    CharacterDetailView(character: character)
```

### 3. Enable the Study tile in `HomeView`

Change `isEnabled: false` → `isEnabled: true` and add the tap action:

```swift
HomeTileView(title: "Study", ..., isEnabled: true) {
    path.append(AppDestination.study)
}
```

---

## New Files

```
KanaFlow/Views/Study/
├── StudyView.swift
├── KanaChartView.swift
├── ChartCellView.swift
└── CharacterDetailView.swift
```

---

## `StudyView.swift`

Top-level study screen. Owns the kana type selection and renders the chart.

**State:**
- `@State private var kanaType: KanaType = .hiragana`

**Layout:**
```
NavigationTitle "Study"
VStack
├── KanaTypePicker (segmented: Hiragana / Katakana)
└── ScrollView
    ├── KanaChartView(group: .main, kanaType: kanaType)
    ├── KanaChartView(group: .dakuten, kanaType: kanaType)
    └── KanaChartView(group: .combination, kanaType: kanaType)
```

Each `KanaChartView` section has its own section header ("Main", "Dakuten", "Combination") and the `ChartCellView` grid below it.

---

## `KanaChartView.swift`

Renders a kana group as a grid of rows. Takes `[KanaCharacter]` pre-filtered by type/group and organizes them into display rows.

**Row grouping logic:**

Characters already have a `row` property (e.g. `"a"`, `"ka"`, `"sa"`). Group and sort by the canonical gojūon row order:

```swift
// Main / Dakuten row order
let rowOrder = ["a","ka","sa","ta","na","ha","ma","ya","ra","wa","n"]

// Combination row order
let comboRowOrder = ["kya","sha","cha","nya","hya","mya","rya","gya","ja","bya","pya"]
```

Within each row, sort by the 5-vowel column order `[a, i, u, e, o]` using the romaji suffix. Gaps (e.g. yi, ye in ya-row) are rendered as empty `ChartCellView` placeholders.

**Layout:**
- `VStack` of rows, each row is an `HStack` of up to 5 `ChartCellView` cells
- Combination group uses rows of 3 (ya/yu/yo columns)
- All cells are a fixed size (e.g. 60×68pt) so the grid aligns cleanly

---

## `ChartCellView.swift`

Individual character cell in the chart grid.

**Parameters:**
- `character: KanaCharacter?` — nil renders an empty spacer cell
- `progress: CharacterProgress?` — used for accuracy tint

**Layout:**
```
RoundedRectangle (60×68pt)
├── kana (font: ~24pt, AppFonts.heading2 or similar)
└── romaji (font: AppFonts.small, AppColors.textSecondary)
```

**Progress tinting (subtle):**
- No attempts yet → `AppColors.cardBackground` (neutral)
- ≥70% accuracy → `AppColors.success.opacity(0.08)` background
- <70% accuracy (with ≥3 attempts) → `AppColors.error.opacity(0.08)` background

**Tap:** navigates to `CharacterDetailView` via `path.append(.characterDetail(character))`.

---

## `CharacterDetailView.swift`

Full-screen detail for a single character. Accessed by tapping any chart cell.

**Parameters:**
- `character: KanaCharacter`

**Sections:**

### Header
- Large kana glyph (`AppFonts.kanaHuge`, ~120pt)
- Romaji in large body text
- Alternate romanizations shown as chips if non-empty (e.g. "shi" also accepts "si")
- Group + type badge (e.g. "Hiragana · Main")

### Stroke Order
Reuses the exact scaling logic already in `QuizPlayView.parsedHintPaths()`. Extract this into a shared helper (e.g. a free function `strokePaths(for character: KanaCharacter, in size: CGFloat) -> [Path]`) so both `QuizPlayView` and `CharacterDetailView` can call it.

The stroke order canvas here is **read-only** (no drawing). It renders revealed strokes in `AppColors.text` at full opacity (not red/hint style).

**Controls:**
```
HStack
├── "Reset" button  — sets revealedCount = 0
├── Spacer
├── stroke counter  — "2 / 3"
└── "Next Stroke" button — increments revealedCount; disabled when all revealed
```

Auto-reveal all strokes on first appearance (i.e. start with `revealedCount = hintPaths.count`) so the user sees the complete character immediately. Tapping "Reset" then "Next Stroke" lets them step through stroke order manually.

**State:**
```swift
@State private var revealedCount: Int = 0   // starts at 0, set to total in .onAppear
private var hintPaths: [Path] { strokePaths(for: character, in: canvasSize) }
```

### Progress (only shown if `totalCount > 0`)
Reads from `ProgressStore`:
```
HStack of 3 StatCells (matching QuizSummaryView style):
├── Accuracy  (e.g. "82%")
├── Type A    (e.g. "14/17")
└── Type B    (e.g. "6/8")
```

---

## `ProgressStore` — New Method

Add a single-character lookup so `CharacterDetailView` and `ChartCellView` can read progress without passing full SwiftData query infrastructure through the view hierarchy:

```swift
func progressFor(characterId: String) -> CharacterProgress? {
    let descriptor = FetchDescriptor<CharacterProgress>(
        predicate: #Predicate { $0.characterId == characterId }
    )
    return (try? context.fetch(descriptor))?.first
}
```

Both `StudyView` and `CharacterDetailView` receive `modelContext` via `@Environment(\.modelContext)` and construct a `ProgressStore` the same way `QuizSetupView` does.

---

## Shared Helper — Extract Stroke Path Logic

Currently `parsedHintPaths(for:)` is a private method on `QuizPlayView`. Move it to a free function in `Logic/` (or inline in a small extension on `KanaCharacter`) so `CharacterDetailView` can use it without duplication:

```swift
// Logic/StrokePaths.swift
func strokePaths(for character: KanaCharacter, in canvasSize: CGFloat) -> [Path] { ... }
```

`QuizPlayView` then calls this function instead of its private method.

---

## File Change Summary

| File | Change |
|------|--------|
| `ContentView.swift` | Add `.study` and `.characterDetail` cases |
| `HomeView.swift` | Enable Study tile, add navigation action |
| `Logic/StrokePaths.swift` | **Create** — extract stroke path logic from QuizPlayView |
| `Views/Quiz/QuizPlayView.swift` | Call `strokePaths()` helper instead of private method |
| `Data/ProgressStore.swift` | Add `progressFor(characterId:)` method |
| `Views/Study/StudyView.swift` | **Create** |
| `Views/Study/KanaChartView.swift` | **Create** |
| `Views/Study/ChartCellView.swift` | **Create** |
| `Views/Study/CharacterDetailView.swift` | **Create** |
| `project.yml` | Add `Views/Study` path (auto-handled by `createIntermediateGroups: true`) |

After creating the new files, run `xcodegen generate` to pick them up.

---

## Out of Scope for 4.1

- Audio pronunciation (Phase 5+)
- Animated stroke-order playback (auto-advancing timer) — manual step-through is sufficient
- "Quiz this character" shortcut from detail view (Phase 4.2)
