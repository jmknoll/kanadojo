# Phase 3 — Spaced Repetition & Progress Dashboard

## Overview

Three deliverables:
1. **3.1** Add an SM-2–based spaced repetition algorithm that drives quiz ordering
2. **3.2** Improve the existing "Struggling" mode using SM-2 scheduling data
3. **3.3** Enable the Stats tile with a full progress dashboard

---

## 3.1 — Algorithm

### Schema additions to `CharacterProgress`

Four new fields with defaults (SwiftData handles this as a lightweight migration — no manual migration step needed):

```swift
var intervalDays: Int        // default: 1   — days until next review
var easeFactor: Double       // default: 2.5 — SM-2 ease multiplier
var consecutiveCorrect: Int  // default: 0   — current correct streak
var nextReviewDate: Date?    // default: nil — nil means "never reviewed, show freely"
```

Two new computed properties on `CharacterProgress`:

```swift
// 0.0 (unknown/weak) → 1.0 (strong)
// Combines accuracy with confidence (attempt count) to avoid overfitting on 1-2 answers
var strength: Double {
    guard totalCount > 0 else { return 0 }
    let confidence = min(Double(totalCount) / 10.0, 1.0)
    return accuracy * confidence
}

// True when the character is scheduled for review today or earlier
var isDue: Bool {
    guard let next = nextReviewDate else { return true } // never reviewed = always due
    return next <= Date()
}
```

### Mastery levels

Add `MasteryLevel` to `KanaModels.swift` (alongside the other enums):

```swift
enum MasteryLevel: Int, CaseIterable {
    case new       = 0  // never attempted
    case learning  = 1  // consecutiveCorrect < 2
    case reviewing = 2  // consecutiveCorrect >= 2, intervalDays < 21
    case mastered  = 3  // intervalDays >= 21

    var displayName: String { ... }
    var color: Color { ... } // gray / yellow / blue / green
}
```

Add to `CharacterProgress`:

```swift
var masteryLevel: MasteryLevel {
    if totalCount == 0 { return .new }
    if consecutiveCorrect < 2 { return .learning }
    if intervalDays < 21 { return .reviewing }
    return .mastered
}
```

### SM-2 update logic

Add a free function `applySpacedRepetition(to:correct:)` in `QuizLogic.swift`:

```swift
func applySpacedRepetition(to progress: CharacterProgress, correct: Bool) {
    if correct {
        switch progress.consecutiveCorrect {
        case 0:  progress.intervalDays = 1
        case 1:  progress.intervalDays = 6
        default: progress.intervalDays = Int((Double(progress.intervalDays) * progress.easeFactor).rounded())
        }
        progress.easeFactor = max(1.3, progress.easeFactor + 0.1)
        progress.consecutiveCorrect += 1
    } else {
        progress.consecutiveCorrect = 0
        progress.intervalDays = 1
        progress.easeFactor = max(1.3, progress.easeFactor - 0.2)
    }
    progress.nextReviewDate = Calendar.current.date(
        byAdding: .day, value: progress.intervalDays, to: Date()
    )
}
```

Call this from `ProgressStore.updateProgress()` after the existing correctCount/incorrectCount update.

### Weighted quiz ordering

Replace the random shuffle in `QuizViewModel.load()` with a **weighted sample**: characters with lower `strength` are more likely to be selected. This means even in Full Practice mode, weak characters surface more often without being shown exclusively.

Add `weightedSample(_:count:)` to `QuizLogic.swift`:

```swift
func weightedSample(_ pool: [KanaCharacter], count: Int, progressDict: [String: CharacterProgress]) -> [KanaCharacter] {
    // Weight = (1.0 - strength), floored at 0.1 so mastered chars still appear occasionally
    let weights = pool.map { char -> Double in
        let strength = progressDict[char.id]?.strength ?? 0
        return max(0.1, 1.0 - strength)
    }
    // Weighted random selection without replacement
    ...
    return selected
}
```

`QuizViewModel.load()` calls `weightedSample` in Full Practice mode and continues to use the existing filter for Struggling mode (updated in 3.2).

`ProgressStore` needs a new method `allProgressDict() -> [String: CharacterProgress]` returning all records keyed by id, so `QuizViewModel` can pass it to `weightedSample`.

---

## 3.2 — Weak Character Mode

### Update `getStrugglingIds`

The current implementation filters on `accuracy < 0.6 && totalCount > 0`. Replace with a smarter definition that combines SM-2 scheduling with accuracy:

```swift
func getStrugglingIds(kanaType:, group:) -> [String] {
    // A character is "struggling" if:
    //   (a) it is due for review, OR
    //   (b) it has been attempted and has accuracy < 0.7
}
```

### Quiz ordering in Struggling mode

In `QuizViewModel.load()`, when `practiceMode == .struggling`, pass the filtered pool through the same `weightedSample` used by Full Practice — but with a stronger weight floor removed so the bias toward weak characters is more pronounced. Concretely, use `weight = (1.0 - strength)` with a floor of `0.01` instead of `0.1`, making the weakest characters appear toward the front much more often while still preserving the random element that prevents the order from being identical every session.

---

## 3.3 — Progress Dashboard

### Streak tracking

Streak lives in `UserDefaults` (not SwiftData — it is app-session metadata, not character study data).

New file `Data/StreakStore.swift`:

```swift
final class StreakStore {
    static let shared = StreakStore()
    private let defaults = UserDefaults.standard

    var currentStreak: Int { get/set via defaults }
    var longestStreak: Int { get/set via defaults }
    var lastStudyDate: Date? { get/set via defaults }

    // Call once per quiz session (from ProgressStore.updateProgress)
    func recordStudyToday() {
        // If lastStudyDate == yesterday → streak += 1
        // If lastStudyDate == today → no change
        // Otherwise → streak = 1
        // Update longestStreak if currentStreak > longestStreak
    }
}
```

`ProgressStore.updateProgress()` calls `StreakStore.shared.recordStudyToday()`.

### New destination

Add `.stats` to `AppDestination` in `ContentView.swift`. Enable the Stats tile in `HomeView.swift`.

### `StatsView.swift`

New file `Views/Stats/StatsView.swift`. Uses `@Query private var allProgress: [CharacterProgress]` to drive all sections.

**Layout:**

```
NavigationTitle "Stats"

ScrollView
├── Summary strip (3 chips side by side)
│     ├── 🔥 X day streak
│     ├── X / 214 practiced
│     └── X% accuracy (overall, across all attempted chars)
│
├── Mastery Breakdown section
│     Header: "Mastery"
│     4 rows — one per MasteryLevel
│     Each row:  [color dot]  [level name]  [count]  [bar fill]
│     Bar fill = count / 214, colored by level
│
└── Needs Practice section
      Header: "Needs Practice"  (only shown if any due/weak chars exist)
      Characters where isDue || accuracy < 0.7, sorted by strength ascending
      Each row:
        [kana char, large]  [romaji]  [accuracy badge]  [due chip if isDue]
        Tappable → CharacterDetailView
```

The mastery breakdown doubles as overall progress: when the "Mastered" bar fills the screen, the user knows they're done.

### `MasteryBadge.swift`

Small reusable view used in `StatsView` character rows and optionally in `CharacterDetailView`:

```swift
struct MasteryBadge: View {
    let level: MasteryLevel
    // Colored pill: "Learning", "Reviewing", "Mastered"
    // "New" shows nothing (no badge)
}
```

---

## File Change Summary

| File | Change |
|---|---|
| `Data/CharacterProgress.swift` | Add 4 SM-2 fields, `strength`, `isDue`, `masteryLevel` |
| `KanaModels.swift` | Add `MasteryLevel` enum |
| `Logic/QuizLogic.swift` | Add `applySpacedRepetition()`, `weightedSample()` |
| `Data/ProgressStore.swift` | Call `applySpacedRepetition` in `updateProgress`, update `getStrugglingIds`, add `allProgressDict()` |
| `Data/StreakStore.swift` | **Create** — UserDefaults-backed streak tracking |
| `ViewModels/QuizViewModel.swift` | Use `weightedSample` in Full mode, sort by strength in Struggling mode |
| `Views/Stats/StatsView.swift` | **Create** |
| `Views/Stats/MasteryBadge.swift` | **Create** |
| `ContentView.swift` | Add `.stats` destination |
| `HomeView.swift` | Enable Stats tile |

After adding new files, run `xcodegen generate`.

---

## What's explicitly out of scope

- Per-session history log (would require a new SwiftData model and schema migration)
- Cloud sync of progress
- Resetting individual character progress
- The "Review" queue as a separate app mode (due characters surface through the existing Struggling mode)
