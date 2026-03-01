# Kana Flow Product Requirements Document

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

### Phase 5: Polish & Enhancements

**5.0 Notifications**

- [ ] Add settings page with ability to enable/disable notifications
- [ ] Add daily reminder push notification
- [ ] On first open, add notification permission popup (with text about the importance of daily reminders)

**5.1 ML Handwriting Recognition**

- [ ] Research and select model/API (Core ML or cloud)
- [ ] Integrate recognition
- [ ] Confidence threshold tuning

**5.2 UX Improvements**

- [ ] Animations and transitions
- [ ] Sound effects
- [x] Dark mode support
- [ ] Haptic feedback
- [ ] Some improved version of stroke order in study mode

**5.3 Gamification**

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
