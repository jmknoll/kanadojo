# Row Selection Filter — Implementation Plan

## Overview

Add an optional row-selection section to the quiz setup screen. Users can multi-select specific rows (e.g. "a", "ka", "sa") within the chosen Character Group. Default is all rows.

---

## Files to Change

| File | Change |
|------|--------|
| `Models/KanaModels.swift` | Add `selectedRows: [String]` to `QuizConfig` |
| `Models/KanaData.swift` | Add `getAvailableRows(kanaType:group:)` + row filter to `getCharacters` |
| `ViewModels/QuizSetupViewModel.swift` | Add `selectedRows` state, reset logic, update `availableCount`/`canStart`/`config` |
| `ViewModels/QuizViewModel.swift` | Apply row filter after `getCharacters` call in `load` |
| `Data/ProgressStore.swift` | Apply row filter in `getStrugglingIds` |
| `Views/QuizSetup/QuizSetupView.swift` | Add `RowSelectorView` section + `onChange` reset |
| `Views/QuizSetup/RowSelectorView.swift` | **New file** — collapsible multi-select chip UI |

---

## Step-by-Step

### Step 1 — `KanaModels.swift`: Update `QuizConfig`

Add `selectedRows: [String]` (empty = all rows):

```swift
struct QuizConfig {
    let kanaType: KanaTypeSelection
    let group: GroupSelection
    let quizType: QuizType
    let practiceMode: PracticeMode
    let questionCount: QuestionCount
    let selectedRows: [String]   // new — empty means "all rows"
}
```

### Step 2 — `KanaData.swift`: Add helpers

**`getAvailableRows`** — returns ordered, deduplicated row keys for a given type+group. Use `NSOrderedSet` or manual dedup to preserve declaration order from the data arrays:

```swift
static func getAvailableRows(kanaType: KanaTypeSelection, group: GroupSelection) -> [String] {
    var seen = Set<String>()
    return getCharacters(kanaType: kanaType, group: group)
        .compactMap { char -> String? in
            guard seen.insert(char.row).inserted else { return nil }
            return char.row
        }
}
```

**`getCharacters` overload with row filter:**

```swift
static func getCharacters(kanaType: KanaTypeSelection, group: GroupSelection, rows: [String]) -> [KanaCharacter] {
    let base = getCharacters(kanaType: kanaType, group: group)
    if rows.isEmpty { return base }
    let rowSet = Set(rows)
    return base.filter { rowSet.contains($0.row) }
}
```

### Step 3 — `QuizSetupViewModel.swift`: Add row state

```swift
var selectedRows: Set<String> = []

var availableRows: [String] {
    KanaData.getAvailableRows(kanaType: kanaType, group: group)
}

// Update availableCount and canStart to use row-filtered characters:
private var filteredCharacters: [KanaCharacter] {
    KanaData.getCharacters(kanaType: kanaType, group: group, rows: Array(selectedRows))
}

var availableCount: Int {
    let chars = filteredCharacters
    if practiceMode == .struggling {
        return min(strugglingCount, questionCount == .all ? Int.max : questionCount.rawValue)
    }
    if questionCount == .all { return chars.count }
    return min(chars.count, questionCount.rawValue)
}

var canStart: Bool {
    if practiceMode == .struggling { return strugglingCount > 0 }
    return filteredCharacters.count > 0
}

var config: QuizConfig {
    QuizConfig(
        kanaType: kanaType,
        group: group,
        quizType: quizType,
        practiceMode: practiceMode,
        questionCount: questionCount,
        selectedRows: Array(selectedRows)
    )
}
```

Also reset `selectedRows` when `kanaType` or `group` changes (handled in view via `.onChange`).

`refreshStrugglingCount` needs to pass rows to `getStrugglingIds` (Step 5).

### Step 4 — `RowSelectorView.swift`: New UI component

A `DisclosureGroup` that expands to show a flow-layout of multi-select chips. When collapsed, show a summary ("All rows" or "3 rows selected").

```
┌─────────────────────────────────┐
│ Rows  ▼ All rows                │  ← collapsed header
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Rows  ▲                         │  ← expanded
│ [a] [ka] [sa] [ta] [na]         │
│ [ha] [ma] [ya] [ra] [wa] [n]    │
└─────────────────────────────────┘
```

Chips use the existing `ChipView`. Selecting a chip toggles the row in `selectedRows`. If all rows are selected, it's equivalent to none selected (reset to empty).

### Step 5 — `ProgressStore.swift`: Apply row filter to `getStrugglingIds`

Update the signature to accept `rows: [String]` and filter the valid character pool before comparing IDs.

### Step 6 — `QuizViewModel.swift`: Apply row filter in `load`

```swift
var pool = KanaData.getCharacters(kanaType: config.kanaType, group: config.group, rows: config.selectedRows)
```

Replace the existing `getCharacters` call (line 43).

### Step 7 — `QuizSetupView.swift`: Wire everything up

- Add `RowSelectorView` section between Character Group and Quiz Type
- Add `.onChange(of: vm.kanaType)` and `.onChange(of: vm.group)` to reset `vm.selectedRows = []` (can extend existing `onChange` blocks)
- Pass `vm.selectedRows` binding and `vm.availableRows` to `RowSelectorView`

---

## UI Placement in `QuizSetupView`

```
Kana Type      [Hiragana] [Katakana] [Both]
Character Group [All] [Main] [Dakuten] [Combos]
Rows           ▼ All rows            ← new, collapsible
Quiz Type      [Type A] [Type B]
Practice Mode  [Full] [Struggling]
Questions      [10] [20] [All]
──────────────────────────────────
12 questions
[       Start Quiz       ]
```

---

## Edge Cases

- When `group` = All, `getAvailableRows` returns rows from all groups combined. The row picker still works — selecting "a" and "ga" across groups is valid.
- When `selectedRows` is non-empty but the type/group changes, reset to empty (all rows) to avoid phantom selections.
- When all available rows are manually selected, treat identically to empty (all rows) — the filter result is the same.
- `ProgressStore.getStrugglingIds` must apply the same row filter so the struggling count matches the actual quiz pool.
