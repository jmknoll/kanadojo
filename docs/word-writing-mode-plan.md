# Phase 7 — Word Writing Mode Implementation Plan

## Overview

Add a Word Writing mode as a third top-level destination alongside Quiz and Study. Users are shown an English meaning and romaji reading, then write the full word in kana on the drawing canvas. The result is self-graded. Progress is tracked per word in a new SwiftData model.

---

## New Files

```
KanaScript/
├── Models/
│   └── WordModels.swift          # WordEntry, WordCategory, WordQuizConfig structs + enums
├── Data/
│   ├── WordData.swift            # Static word list (~200 entries)
│   └── WordProgressStore.swift   # CRUD + weighted session building
├── ViewModels/
│   └── WordQuizViewModel.swift   # @Observable session state machine
└── Views/
    └── WordWriting/
        ├── WordSetupView.swift
        ├── WordSetupViewModel.swift (or inline in WordSetupView)
        ├── WordQuizPlayView.swift
        ├── WordPromptView.swift
        ├── WordGradingOverlayView.swift
        └── WordQuizSummaryView.swift
```

---

## 1. Models — `Models/WordModels.swift`

### `WordCategory`

```swift
enum WordCategory: String, CaseIterable, Codable {
    case foodAndDrink   = "Food & Drink"
    case body           = "Body"
    case timeCalendar   = "Time & Calendar"
    case people         = "People"
    case nature         = "Nature"
    case places         = "Places"
    case dailyLife      = "Daily Life"
    case adjectives     = "Adjectives"
    case verbs          = "Verbs"
    case other          = "Other"
}
```

### `WordScriptType`

Controls whether a session uses the hiragana or katakana rendering of a word. This is separate from `KanaType` to avoid confusion with the existing kana-character quiz types.

```swift
enum WordScriptType: String, CaseIterable, Codable {
    case hiragana
    case katakana
    case mixed

    var displayName: String { ... }
}
```

### `WordEntry`

```swift
struct WordEntry: Identifiable {
    let id: String          // stable slug, e.g. "gohan-hiragana"
    let hiragana: String    // e.g. "ごはん"
    let katakana: String    // e.g. "" (empty if no natural katakana form)
    let romaji: String      // e.g. "gohan"
    let english: String     // e.g. "rice / meal"
    let category: WordCategory
    let primaryScript: WordScriptType  // .hiragana or .katakana (drives default session)

    // The kana string to present in a given session
    func kana(for scriptType: WordScriptType) -> String? {
        switch scriptType {
        case .hiragana: return hiragana.isEmpty ? nil : hiragana
        case .katakana: return katakana.isEmpty ? nil : katakana
        case .mixed:    return hiragana.isEmpty ? katakana : hiragana
        }
    }
}
```

Words whose `primaryScript == .katakana` (loanwords with no meaningful hiragana spelling, e.g. コーヒー) set `hiragana = ""`. These words are excluded when the session type is `.hiragana`.

### `WordQuizConfig`

```swift
struct WordQuizConfig {
    let scriptType: WordScriptType
    let selectedCategories: [WordCategory]  // empty = all categories
    let sessionLength: WordSessionLength
    let wordPool: [WordEntry]  // pre-built by WordSetupViewModel
}

enum WordSessionLength: Int, CaseIterable {
    case ten    = 10
    case twenty = 20
    case thirty = 30

    var displayName: String { "\(rawValue)" }
}
```

Add `WordQuizConfig: Hashable` conformance extension (matching the pattern for `QuizConfig: Hashable` in `ContentView.swift`) so it can be used as a `NavigationPath` value.

---

## 2. Data Layer — `Data/WordData.swift`

A single file containing the static word list as a `WordData` enum (matching the style of `KanaData`):

```swift
enum WordData {
    static let allWords: [WordEntry] = [
        WordEntry(id: "gohan-hiragana", hiragana: "ごはん", katakana: "",
                  romaji: "gohan", english: "rice / meal",
                  category: .foodAndDrink, primaryScript: .hiragana),
        // ... ~200 total entries
    ]

    static func getWords(
        scriptType: WordScriptType,
        categories: [WordCategory]  // empty = all
    ) -> [WordEntry] {
        allWords
            .filter { entry in
                // Exclude entries with no kana for the requested script
                entry.kana(for: scriptType) != nil
            }
            .filter { entry in
                categories.isEmpty || categories.contains(entry.category)
            }
    }
}
```

Populate from the Word Reference Data section of the PRD (~200 entries). Exclude words with fewer than 3 kana characters from `allWords` (they are in the PRD reference tables for completeness but are not quiz candidates).

---

## 3. Progress Model — `Data/WordProgress.swift`

New `@Model` class, mirroring `CharacterProgress`:

```swift
@Model
final class WordProgress {
    @Attribute(.unique) var wordID: String
    var correctCount: Int
    var incorrectCount: Int
    var lastPracticed: Date?

    // SM-2 fields (same algorithm as CharacterProgress)
    var intervalDays: Int
    var easeFactor: Double
    var consecutiveCorrect: Int
    var nextReviewDate: Date?

    init(wordID: String) {
        self.wordID = wordID
        self.correctCount = 0
        self.incorrectCount = 0
        self.lastPracticed = nil
        self.intervalDays = 1
        self.easeFactor = 2.5
        self.consecutiveCorrect = 0
        self.nextReviewDate = nil
    }

    var totalCount: Int { correctCount + incorrectCount }

    var accuracy: Double {
        totalCount > 0 ? Double(correctCount) / Double(totalCount) : 0.0
    }

    // 0.0 (unknown/weak) → 1.0 (strong); matches CharacterProgress.strength formula
    var strength: Double {
        guard totalCount > 0 else { return 0 }
        let confidence = min(Double(totalCount) / 10.0, 1.0)
        return accuracy * confidence
    }

    var isDue: Bool {
        let attempted = totalCount > 0
        guard let next = nextReviewDate else { return attempted }
        return next <= Date()
    }
}
```

### App init — add `WordProgress` to `ModelContainer`

In `KanaFlowApp.swift`, update the container to include both models:

```swift
container = try ModelContainer(for: CharacterProgress.self, WordProgress.self)
```

SwiftData creates a new `ZWORDPROGRESS` table automatically on first launch; no column migration needed. The existing SQLite shim in `migrateStoreIfNeeded()` does not need updating — it targets `ZCHARACTERPROGRESS` only and is a no-op when the store is already migrated.

---

## 4. Progress Store — `Data/WordProgressStore.swift`

```swift
@MainActor
final class WordProgressStore {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func updateProgress(wordID: String, correct: Bool) {
        let progress = fetchOrCreate(wordID: wordID)
        if correct { progress.correctCount += 1 } else { progress.incorrectCount += 1 }
        progress.lastPracticed = Date()
        applySpacedRepetition(to: progress, correct: correct)
        StreakStore.shared.recordStudyToday()
        try? context.save()
    }

    func allProgressDict() -> [String: WordProgress] {
        let descriptor = FetchDescriptor<WordProgress>()
        guard let all = try? context.fetch(descriptor) else { return [:] }
        return Dictionary(uniqueKeysWithValues: all.map { ($0.wordID, $0) })
    }

    private func fetchOrCreate(wordID: String) -> WordProgress {
        let descriptor = FetchDescriptor<WordProgress>(
            predicate: #Predicate { $0.wordID == wordID }
        )
        if let existing = (try? context.fetch(descriptor))?.first { return existing }
        let new = WordProgress(wordID: wordID)
        context.insert(new)
        return new
    }
}
```

`applySpacedRepetition(to:correct:)` — reuse the free function from `Logic/QuizLogic.swift`. That function currently takes a `CharacterProgress` and a `QuizType`. Extract the SM-2 arithmetic into a protocol or a generic helper so both `CharacterProgress` and `WordProgress` can share it, or duplicate the function as a simple overload that takes the four SM-2 fields by inout reference.

**Weighted session building** (called by `WordSetupViewModel`):

```swift
func buildSessionPool(
    from words: [WordEntry],
    count: Int,
    progressDict: [String: WordProgress]
) -> [WordEntry] {
    // Weight = max(0.1, 1.0 - strength), same floor as QuizViewModel Full Practice mode
    weightedSample(words, count: count, progressDict: progressDict)
}
```

---

## 5. Navigation — `ContentView.swift`

Add two new cases to `AppDestination`:

```swift
enum AppDestination: Hashable {
    // ... existing cases ...
    case wordWriting
    case wordQuiz(config: WordQuizConfig)
}
```

Add `WordQuizConfig: Hashable` extension below the existing `QuizConfig: Hashable` extension.

Add destination handling in the `navigationDestination` switch:

```swift
case .wordWriting:
    WordSetupView(path: $path)
case .wordQuiz(let config):
    WordQuizPlayView(config: config, path: $path)
```

---

## 6. Home Screen — `HomeView.swift`

Add a new tile after the Stats tile:

```swift
HomeTileView(
    title: "Words",
    subtitle: "Write complete words in kana",
    icon: "character.book.closed",
    isEnabled: true
) {
    path.append(AppDestination.wordWriting)
}
```

---

## 7. Setup — `WordSetupView.swift`

**State (inline or in a lightweight `@Observable WordSetupViewModel`):**

```
@State scriptType: WordScriptType = .hiragana
@State selectedCategories: [WordCategory] = []   // empty = all
@State sessionLength: WordSessionLength = .twenty
@AppStorage("wordWritingOnboardingSeen") var onboardingSeen = false
```

**Layout:**

```
NavigationTitle "Words"

ScrollView
├── KanaTypePicker (segmented: Hiragana / Katakana / Mixed)
│
├── SectionHeaderView "Categories"
│   ChipSelectorView (multi-select, same GroupChipSelectorView pattern)
│   Each chip: WordCategory.displayName
│   "All" chip deselects the others (same as row selector behaviour)
│
├── SectionHeaderView "Session Length"
│   Segmented picker: 10 / 20 / 30
│
├── SectionHeaderView "Words Available"
│   Text: "\(filteredCount) words"   (updates reactively)
│
└── "Start" button (disabled if filteredCount == 0)
```

On "Start":
1. Call `WordProgressStore.buildSessionPool(from:count:progressDict:)` to produce a weighted pool.
2. Build `WordQuizConfig` and push `.wordQuiz(config:)` onto `path`.

**First-launch onboarding sheet** — shown once via `@AppStorage("wordWritingOnboardingSeen")`. Brief sheet explaining this is an advanced mode: users write full words, self-grade their own handwriting. Dismiss button sets the flag.

---

## 8. ViewModel — `WordQuizViewModel.swift`

```swift
enum WordQuizState {
    case prompt      // show English + romaji; waiting for user to tap "Start Writing"
    case drawing     // canvas active
    case grading     // GradingOverlay visible
    case complete    // session finished
}

@Observable
final class WordQuizViewModel {
    var state: WordQuizState = .prompt
    var words: [WordEntry] = []
    var currentIndex: Int = 0
    var results: [(word: WordEntry, correct: Bool)] = []
    var submittedStrokes: [Stroke] = []
    var hintUsed: Bool = false

    var currentWord: WordEntry? { /* bounds-checked */ }
    var progress: Double { /* currentIndex / words.count */ }

    func load(config: WordQuizConfig) {
        words = config.wordPool
        currentIndex = 0
        results = []
        state = words.isEmpty ? .complete : .prompt
    }

    @MainActor
    func startDrawing() { state = .drawing }

    @MainActor
    func submitDrawing(_ strokes: [Stroke]) {
        submittedStrokes = strokes
        state = .grading
    }

    @MainActor
    func submitGrade(_ wasCorrect: Bool, store: WordProgressStore, scriptType: WordScriptType) {
        guard let word = currentWord else { return }
        let effective = hintUsed ? false : wasCorrect
        results.append((word: word, correct: effective))
        store.updateProgress(wordID: word.id, correct: effective)
        advance()
    }

    func recordHintUsed() { hintUsed = true }

    private func advance() {
        hintUsed = false
        submittedStrokes = []
        let next = currentIndex + 1
        if next >= words.count { state = .complete } else { currentIndex = next; state = .prompt }
    }
}
```

---

## 9. Quiz Play — `WordQuizPlayView.swift`

Top-level view for a word quiz session. Owns the `WordQuizViewModel` and switches between sub-views based on state.

```swift
struct WordQuizPlayView: View {
    let config: WordQuizConfig
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = WordQuizViewModel()
    @State private var canvasSize: CGFloat = 300

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .prompt:
                WordPromptView(
                    word: viewModel.currentWord!,
                    scriptType: config.scriptType,
                    progress: viewModel.progress,
                    onHintUsed: { viewModel.recordHintUsed() },
                    onStartDrawing: { viewModel.startDrawing() }
                )
            case .drawing:
                // Reuse DrawingCanvasView with a "Done" button
                wordCanvasView
            case .grading:
                wordGradingOverlay
            case .complete:
                WordQuizSummaryView(results: viewModel.results, path: $path)
            }
        }
        .onAppear { viewModel.load(config: config) }
        .navigationBarBackButtonHidden(viewModel.state != .complete)
    }
}
```

The canvas section wraps the existing `DrawingCanvasView` — no structural changes to `DrawingCanvasView` needed. A "Done" button below (or in the toolbar) calls `viewModel.submitDrawing(strokes)`.

---

## 10. Prompt Screen — `WordPromptView.swift`

```
NavigationTitle ""   (no title; progress bar handles session position)

ProgressBarView (reuse existing component, value: viewModel.progress)

Spacer

VStack (centred)
├── Text(english)      font: AppFonts.heading2,  AppColors.textMuted
├── Text(romaji)       font: AppFonts.heading1,  AppColors.text

Spacer

"Show kana" TextButton (destructive tint — hint)
    → reveals kana inline and calls onHintUsed()
    → once tapped: label becomes the kana string and button is disabled

"Start Writing" primary button
    → calls onStartDrawing()
```

The kana hint shows the correct kana in a muted box below the romaji line. Once revealed, the button label is replaced by the kana string itself so the user can reference it while drawing. Because `onHintUsed()` sets `viewModel.hintUsed = true`, the grading overlay will force "Incorrect" regardless of the user's self-assessment.

---

## 11. Grading Overlay — `WordGradingOverlayView.swift`

Closely mirrors `GradingOverlayView`. Because there is no embedding ML model for multi-character words in Phase 7, this view always shows the self-grade buttons (no quality score bar).

```
VStack
├── "How did you do?"  heading
├── Hint warning (if hintUsed) — reuse exact layout from GradingOverlayView
├── Comparison row:
│     Left:  Canvas replay of user's strokes (reuse pathFromStrokes helper)
│     Right: Correct kana string in large text (font: ~80pt, matching GradingOverlayView)
└── Self-grade buttons:  "Got it wrong"  |  "Got it right"
      (same layout as GradingOverlayView.selfGradeButtons)
      "Got it right" hidden if hintUsed
```

`onContinue(Bool)` callback maps to `viewModel.submitGrade(_:store:scriptType:)` called from `WordQuizPlayView`.

---

## 12. Summary — `WordQuizSummaryView.swift`

```
NavigationTitle "Session Complete"

ScrollView
├── Summary strip (2 stats side by side, matching QuizSummaryView style)
│     ├── Accuracy  e.g. "75%"
│     └── Words     e.g. "15 / 20"
│
└── Results list
      ForEach results:
        HStack
        ├── kana string        (font: ~22pt, AppColors.text)
        ├── romaji + english   (stacked, AppColors.textSecondary)
        └── checkmark / xmark  (AppColors.success / AppColors.error)

"Done" button → path.removeLast() to pop back to WordSetupView
```

---

## 13. Stats Integration — `StatsView.swift`

Add a "Words" section below the existing Needs Practice section. Keep it collapsed by default with a disclosure group:

```
DisclosureGroup "Word Writing") {
    // Two summary chips: Total practiced, Overall accuracy
    // List of word entries with correct/incorrect counts (same row style as character browser)
}
```

`StatsView` already uses `@Query` for `CharacterProgress`. Add a second `@Query` for `WordProgress`:

```swift
@Query private var wordProgress: [WordProgress]
```

---

## File Change Summary

| File | Change |
|---|---|
| `Models/WordModels.swift` | **Create** — `WordEntry`, `WordCategory`, `WordScriptType`, `WordQuizConfig`, `WordSessionLength` |
| `Data/WordData.swift` | **Create** — static `~200` word list |
| `Data/WordProgress.swift` | **Create** — `@Model` SwiftData class |
| `Data/WordProgressStore.swift` | **Create** — CRUD + weighted session builder |
| `App/KanaFlowApp.swift` | Add `WordProgress.self` to `ModelContainer` |
| `ContentView.swift` | Add `.wordWriting` and `.wordQuiz` destinations + `WordQuizConfig: Hashable` |
| `Views/Home/HomeView.swift` | Add "Words" `HomeTileView` |
| `Views/WordWriting/WordSetupView.swift` | **Create** |
| `Views/WordWriting/WordQuizPlayView.swift` | **Create** |
| `Views/WordWriting/WordPromptView.swift` | **Create** |
| `Views/WordWriting/WordGradingOverlayView.swift` | **Create** |
| `Views/WordWriting/WordQuizSummaryView.swift` | **Create** |
| `ViewModels/WordQuizViewModel.swift` | **Create** |
| `Views/Stats/StatsView.swift` | Add `@Query wordProgress` and Words section |
| `project.yml` | `Views/WordWriting` path (auto-handled by `createIntermediateGroups: true`) |

After creating new files, run `xcodegen generate`.

---

## Edge Cases

| Scenario | Handling |
|---|---|
| Session pool smaller than requested count | `buildSessionPool` clamps to `min(count, words.count)` |
| Loanword (e.g. コーヒー) in Hiragana session | `WordData.getWords(scriptType: .hiragana)` excludes entries with empty `hiragana` |
| User taps "Show kana" then draws correctly | `hintUsed = true` → `submitGrade` forces `effective = false` regardless |
| Empty category selection | `selectedCategories == []` treated as "all categories" in `WordData.getWords` |
| "Done" tapped with no strokes on canvas | Allow — canvas replay will be empty; user can self-grade as incorrect |
| First launch with no `WordProgress` records | `WordProgressStore.buildSessionPool` treats missing entries as `strength = 0` (uniform weight) |

---

## Out of Scope for Phase 7

- Embedding-based ML grading for multi-character words (future Phase 8+)
- Stroke order hints for individual characters within a word (too complex for the combined canvas)
- Audio pronunciation of word prompts
- Word-level spaced repetition separate from the session-level ordering (Phase 7 uses weighted selection; a full SM-2 review queue is deferred)
- Resetting individual word progress from the UI
