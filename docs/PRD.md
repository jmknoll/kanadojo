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

### Handwriting Recognition Options

| Approach                                | Pros                   | Cons                       |
| --------------------------------------- | ---------------------- | -------------------------- |
| **ML Model (Core ML / Create ML)**      | Offline, fast, private | Training data, accuracy    |
| **Cloud API (Google Vision, Apple ML)** | High accuracy          | Requires network, cost     |
| **Stroke Matching**                     | Simple, educational    | Less forgiving, complex UI |
| **Self-Grading**                        | Zero complexity        | Relies on user honesty     |

**Recommendation:** Start with self-grading ("Did you get it right?") + optional reveal, then iterate to ML-based recognition.

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

### Phase 5: Handwriting Recognition & Stats Overhaul

See full plan: [docs/handwriting-recognition-plan.md](handwriting-recognition-plan.md)

**5.0 Recognition Engine** (`StrokeRecognition.swift`)

- [ ] Implement stroke normalisation (canvas coords → [0,1]²)
- [ ] Implement resampling to fixed N=64 points
- [ ] Implement DTW distance function
- [ ] Implement greedy stroke matching (user ↔ reference)
- [ ] Compute shape, proportion, stroke order, consistency scores
- [ ] Expose `gradeDrawing(userStrokes:character:priorShapeEMA:) -> StrokeScores`
- [ ] Tune normalisation constants against real drawn characters
- [ ] Handle fallback (nil) when KanjiVG data is missing for a character

**5.1 Data Model**

- [ ] Add `typeBShapeEMA`, `typeBLatestShape`, `typeBLatestProportion`, `typeBLatestStrokeOrder`, `typeBLatestConsistency`, `typeBLatestOverall` to `CharacterProgress`
- [ ] Add `SchemaV3` + lightweight migration to `AppMigrationPlan.swift`

**5.2 Graded Quiz Flow**

- [ ] Add `pendingScores: StrokeScores?` and `confirmGrade()` to `QuizViewModel`
- [ ] Run `gradeDrawing` on drawing submission; respect hint-used override
- [ ] Create `GradingOverlayView` (side-by-side + score bars + pass/fail + Continue)
- [ ] Wire `GradingOverlayView` into `QuizPlayView`; remove `SelfGradeOverlayView`

**5.3 Stats Page Overhaul**

- [ ] Add kana type filter (All / Hiragana / Katakana) to `StatsView`
- [ ] Filter all derived stats data by selected kana type
- [ ] Add expandable character browser by mastery level (tappable grid → CharacterDetailView)
- [ ] Create `SpiderChartView` (4-axis radar: shape, proportion, stroke order, consistency)
- [ ] Add "Production Quality" section with spider chart to `CharacterDetailView`

### Phase 6: Polish & Enhancements

**6.0 Notifications**

- [ ] Add settings page with ability to enable/disable notifications
- [ ] Add daily reminder push notification
- [ ] On first open, add notification permission popup (with text about the importance of daily reminders)

**6.1 ML Handwriting Recognition**

- [ ] Research and select model/API (Core ML or cloud)
- [ ] Integrate recognition
- [ ] Confidence threshold tuning

**6.2 UX Improvements**

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
