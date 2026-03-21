# Kana Flow Product Requirements Document

## Feature Development Workflow

For every new feature request, before writing any code:

1. **Update this PRD** — add the feature to the relevant section and append a task checklist under the appropriate phase
2. **Create an implementation plan** in `docs/<feature-name>-plan.md` — files to change, step-by-step approach, edge cases

## Overview

Kana Flow is a mobile app for learning Japanese kana (hiragana and katakana) through interactive quizzes. The app focuses on active recall and spaced repetition to help users memorize all 46 basic characters plus their variations. An advanced Word Writing mode builds on this foundation by asking users to write complete words, reinforcing multi-character muscle memory and connecting kana knowledge to real vocabulary.

## Target Users

- Japanese language beginners
- Self-study learners preparing for JLPT N5
- Anyone wanting to refresh their kana knowledge

---

## Core Features

### 1. Top-Level Navigation

Three primary modes:

- **Study Mode** (Phase 4) - Reference charts and learning materials
- **Quiz Mode** (Phase 1) - Active recall testing of individual kana characters
- **Word Writing Mode** (Phase 7) - Advanced handwriting practice using complete Japanese words

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

### 2.4 Word Writing Mode

An advanced mode unlocked after Quiz Mode. Instead of individual characters, users write complete Japanese words from memory, building multi-character muscle memory.

#### 2.4.1 Mode Entry

- Accessible from the home screen as a distinct top-level destination (not nested under Quiz Mode)
- Displays a brief onboarding prompt on first launch explaining the advanced nature of the mode
- No row/subsection selection — the word pool is curated independently of the kana character groups

#### 2.4.2 Word Set Configuration

- **Kana Type**: Hiragana words, Katakana words, or Mixed
- **Category Filter** (optional, multi-select): Food & Drink, Body, Time & Calendar, People & Relationships, Nature, Places, Daily Life, Adjectives, Verbs, Other
- **Session Length**: 10 / 20 / 30 words (default: 20)
- The word pool for a session is drawn from the filtered set, weighted by spaced-repetition weakness score (same algorithm as Phase 3)

#### 2.4.3 Word Writing Quiz Flow

1. **Prompt screen**: Display the word's English meaning and romaji reading (e.g., "water — mizu"). A "Show kana" hint is available but counts the word as incorrect if used.
2. **Canvas**: Full-screen drawing canvas (same component as Type B). The user writes the entire word sequentially across the canvas without character boundaries marked.
3. **Submit**: User taps "Done" when finished writing.
4. **Self-grade overlay**: Show the correct kana spelling (e.g., みず) alongside the user's drawing. User selects "Correct" or "Incorrect". Hint usage forces "Incorrect" automatically.
5. **Advance**: Next word loads immediately; canvas clears between words.
6. **Session summary**: Accuracy rate, words attempted, and a breakdown of correct vs. incorrect words with their kana spellings shown.

#### 2.4.4 Grading

- **Phase 7**: Self-graded (user compares their drawing to the displayed correct kana)
- **Future enhancement**: Embedding-based ML grading — compare the drawn word holistically to a reference using the same CNN pipeline from Phase 5, extended to multi-character inputs

#### 2.4.5 Progress Tracking

- Progress tracked per word entry (separate from per-character kana progress)
- Stored in a new `WordProgress` model: word ID, correct count, incorrect count, last practiced date
- Success rate and weakness weighting computed the same way as `CharacterProgress`
- Word-level progress displayed in a dedicated section of the Stats page (Phase 5.D / future)

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
- [ ] Commit `KanaClassifier.mlmodel` + `kana_labels.json` to `KanaScript/KanaScript/Models/`

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

### Phase 7: Word Writing Mode

**7.1 Word Data Layer**

- [ ] Define `WordEntry` model: `id`, `hiragana`, `katakana`, `romaji`, `english`, `category` (enum), `jlptLevel` (N5/N4 tag for future filtering)
- [ ] Curate initial word list of ~200 common Japanese words (see Word Reference Data below); minimum 3 kana characters per word; exclude standalone particles (は, が, を, に, etc.) and single-mora words
- [ ] Implement `WordData.swift` — static array of all `WordEntry` values, organised by category
- [ ] Add `WordProgress` SwiftData model: `wordID: String`, `correctCount: Int`, `incorrectCount: Int`, `lastPracticed: Date?`; add lightweight schema migration (SchemaV4)
- [ ] Implement `WordProgressStore` — CRUD mirroring `ProgressStore`; exposes weakness-weighted word selection for session building

**7.2 Configuration UI**

- [ ] Add "Word Writing" entry to the home screen alongside Quiz Mode
- [ ] Create `WordSetupView` — kana type picker (Hiragana / Katakana / Mixed), category multi-select chip list, session length picker (10 / 20 / 30)
- [ ] Create `WordSetupViewModel` — holds config state, filters `WordData` by type + category, returns randomised session pool weighted by weakness score
- [ ] First-launch onboarding sheet (shown once via `AppStorage` flag): brief explanation of the advanced mode

**7.3 Word Writing Quiz Flow**

- [ ] Create `WordQuizConfig` — kana type, selected categories, session length, word pool
- [ ] Create `WordQuizViewModel` — session state machine (prompt → drawing → grading → next/summary); tracks hint usage per word; records results to `WordProgressStore`
- [ ] Create `WordPromptView` — displays English meaning + romaji; "Show kana" hint button (marks word incorrect); "Start Writing" button transitions to canvas
- [ ] Reuse `DrawingCanvasView` (existing) with no per-character dividers; canvas clears on word advance
- [ ] Create `WordGradingOverlayView` — shows correct kana spelling at top, user's canvas drawing below, "Correct" / "Incorrect" buttons; hint-used notice if applicable
- [ ] Create `WordQuizSummaryView` — session accuracy, word-by-word result list (kana spelling + correct/incorrect indicator)
- [ ] Wire navigation: `WordSetupView` → `WordPromptView` → canvas → `WordGradingOverlayView` → next word or `WordQuizSummaryView`

**7.4 Progress & Stats Integration**

- [ ] Surface word-level stats in `StatsView`: total words practiced, overall word accuracy, per-word breakdown (collapsed by default, expandable)
- [ ] Apply weakness weighting from `WordProgressStore` in session word selection (words with lower success rates appear more often)

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

## Word Reference Data

### Word Writing Mode — Curated Word List (~200 words)

Selection criteria: common N5–N4 vocabulary, minimum 3 kana characters, no standalone particles, no single-mora words. Hiragana and katakana forms are both listed where a word has a natural katakana counterpart (loanwords appear in katakana only).

**Food & Drink (25 words)**

| English | Hiragana | Katakana (if applicable) | Romaji |
| --- | --- | --- | --- |
| rice / meal | ごはん | — | gohan |
| water | みず | — | mizu |
| tea | おちゃ | — | ocha |
| fish | さかな | — | sakana |
| vegetables | やさい | — | yasai |
| fruit | くだもの | — | kudamono |
| egg | たまご | — | tamago |
| meat | にく | — | niku |
| bread | — | パン | pan |
| coffee | — | コーヒー | koohii |
| juice | — | ジュース | juusu |
| milk | — | ミルク | miruku |
| beer | — | ビール | biiru |
| salt | しお | — | shio |
| sugar | さとう | — | satou |
| soy sauce | しょうゆ | — | shouyu |
| noodles | うどん | — | udon |
| sushi | すし | — | sushi |
| tempura | てんぷら | — | tenpura |
| ramen | — | ラーメン | raamen |
| cake | — | ケーキ | keeki |
| ice cream | — | アイスクリーム | aisukuriimu |
| restaurant | — | レストラン | resutoran |
| menu | — | メニュー | menyuu |
| fork | — | フォーク | fooku |

**Body (15 words)**

| English | Hiragana | Katakana | Romaji |
| --- | --- | --- | --- |
| body | からだ | — | karada |
| head | あたま | — | atama |
| hand / arm | て | — | te |
| eye | め | — | me |
| ear | みみ | — | mimi |
| nose | はな | — | hana |
| mouth | くち | — | kuchi |
| leg / foot | あし | — | ashi |
| heart / mind | こころ | — | kokoro |
| stomach | おなか | — | onaka |
| back | せなか | — | senaka |
| face | かお | — | kao |
| hair | かみ | — | kami |
| tooth | は | — | ha |
| throat | のど | — | nodo |

*(Note: words under 3 kana such as て、め、は are included for completeness but the quiz pool should weight longer words higher. Words of 2 kana or fewer will be excluded from the initial release pool.)*

**Time & Calendar (15 words)**

| English | Hiragana | Romaji |
| --- | --- | --- |
| every day | まいにち | mainichi |
| today | きょう | kyou |
| tomorrow | あした | ashita |
| yesterday | きのう | kinou |
| morning | あさ | asa |
| evening | ゆうがた | yuugata |
| night | よる | yoru |
| week | しゅうかん | shuukan |
| month | つき / げつ | tsuki |
| year | とし / ねん | toshi |
| now | いま | ima |
| time | じかん | jikan |
| Monday | げつようび | getsuyoubi |
| weekend | しゅうまつ | shuumatsu |
| holiday | やすみ | yasumi |

**People & Relationships (15 words)**

| English | Hiragana | Romaji |
| --- | --- | --- |
| friend | ともだち | tomodachi |
| family | かぞく | kazoku |
| person | ひと | hito |
| man | おとこ | otoko |
| woman | おんな | onna |
| child | こども | kodomo |
| teacher | せんせい | sensei |
| student | がくせい | gakusei |
| mother | おかあさん | okaasan |
| father | おとうさん | otousan |
| older sister | おねえさん | oneesan |
| older brother | おにいさん | oniisan |
| husband | おっと | otto |
| wife | つま | tsuma |
| foreigner | がいじん | gaijin |

**Nature (15 words)**

| English | Hiragana | Romaji |
| --- | --- | --- |
| sky | そら | sora |
| sea / ocean | うみ | umi |
| mountain | やま | yama |
| river | かわ | kawa |
| tree | き | ki |
| flower | はな | hana |
| moon | つき | tsuki |
| star | ほし | hoshi |
| sun | たいよう | taiyou |
| rain | あめ | ame |
| snow | ゆき | yuki |
| wind | かぜ | kaze |
| cloud | くも | kumo |
| forest | もり | mori |
| island | しま | shima |

**Places (20 words)**

| English | Hiragana | Katakana | Romaji |
| --- | --- | --- | --- |
| school | がっこう | — | gakkou |
| hospital | びょういん | — | byouin |
| station | えき | — | eki |
| airport | くうこう | — | kuukou |
| post office | ゆうびんきょく | — | yuubinkyoku |
| supermarket | — | スーパー | suupaa |
| convenience store | — | コンビニ | konbini |
| department store | — | デパート | depaato |
| hotel | — | ホテル | hoteru |
| bank | ぎんこう | — | ginkou |
| library | としょかん | — | toshokan |
| park | こうえん | — | kouen |
| shrine | じんじゃ | — | jinja |
| temple | おてら | — | otera |
| museum | はくぶつかん | — | hakubutsukan |
| road | みち | — | michi |
| town | まち | — | machi |
| country | くに | — | kuni |
| house | いえ | — | ie |
| room | へや | — | heya |

**Daily Life (20 words)**

| English | Hiragana | Katakana | Romaji |
| --- | --- | --- | --- |
| train | でんしゃ | — | densha |
| car | くるま | — | kuruma |
| bus | — | バス | basu |
| taxi | — | タクシー | takushii |
| bicycle | じてんしゃ | — | jitensha |
| telephone | でんわ | — | denwa |
| television | — | テレビ | terebi |
| computer | — | パソコン | pasokon |
| smartphone | — | スマホ | sumaho |
| book | ほん | — | hon |
| newspaper | しんぶん | — | shinbun |
| money | おかね | — | okane |
| clothes | ふく | — | fuku |
| door | ドア | ドア | doa |
| window | まど | — | mado |
| table | — | テーブル | teebu |
| chair | — | いす | isu |
| bag | かばん | — | kaban |
| key | かぎ | — | kagi |
| umbrella | かさ | — | kasa |

**Adjectives (25 words)**

| English | Hiragana | Romaji |
| --- | --- | --- |
| big | おおきい | ookii |
| small | ちいさい | chiisai |
| new | あたらしい | atarashii |
| old | ふるい | furui |
| expensive / tall | たかい | takai |
| cheap / low | やすい | yasui |
| hot (temp) | あつい | atsui |
| cold (temp) | さむい | samui |
| good | いい / よい | ii / yoi |
| bad | わるい | warui |
| fast / early | はやい | hayai |
| slow / late | おそい | osoi |
| long | ながい | nagai |
| short | みじかい | mijikai |
| heavy | おもい | omoi |
| light (weight) | かるい | karui |
| easy | かんたん | kantan |
| difficult | むずかしい | muzukashii |
| interesting | おもしろい | omoshiroi |
| boring | つまらない | tsumaranai |
| busy | いそがしい | isogashii |
| kind | やさしい | yasashii |
| beautiful | きれい | kirei |
| delicious | おいしい | oishii |
| scary | こわい | kowai |

**Verbs (30 words)**

| English | Dictionary Form (hiragana) | Romaji |
| --- | --- | --- |
| to eat | たべる | taberu |
| to drink | のむ | nomu |
| to see / watch | みる | miru |
| to listen / hear | きく | kiku |
| to speak | はなす | hanasu |
| to read | よむ | yomu |
| to write | かく | kaku |
| to go | いく | iku |
| to come | くる | kuru |
| to return home | かえる | kaeru |
| to buy | かう | kau |
| to sell | うる | uru |
| to use | つかう | tsukau |
| to make | つくる | tsukuru |
| to think | おもう | omou |
| to know | しる | shiru |
| to understand | わかる | wakaru |
| to wait | まつ | matsu |
| to meet | あう | au |
| to sleep | ねる | neru |
| to wake up | おきる | okiru |
| to work | はたらく | hataraku |
| to study | べんきょうする | benkyou suru |
| to play | あそぶ | asobu |
| to run | はしる | hashiru |
| to walk | あるく | aruku |
| to open | あける | akeru |
| to close | しめる | shimeru |
| to give | あげる | ageru |
| to receive | もらう | morau |

**Other Common Words (20 words)**

| English | Hiragana | Katakana | Romaji |
| --- | --- | --- | --- |
| language | ことば | — | kotoba |
| Japanese language | にほんご | — | nihongo |
| English language | えいご | — | eigo |
| number | かず | — | kazu |
| colour | いろ | — | iro |
| music | おんがく | — | ongaku |
| movie | えいが | — | eiga |
| game | — | ゲーム | geemu |
| sport | — | スポーツ | supootsu |
| health | けんこう | — | kenkou |
| dream | ゆめ | — | yume |
| love | あい | — | ai |
| thank you | ありがとう | — | arigatou |
| sorry | ごめんなさい | — | gomennasai |
| please (request) | おねがい | — | onegai |
| welcome | ようこそ | — | youkoso |
| goodbye | さようなら | — | sayounara |
| congratulations | おめでとう | — | omedetou |
| let's eat | いただきます | — | itadakimasu |
| that's all | ごちそうさま | — | gochisousama |

### Word Pool Filtering Rules

- Words with fewer than 3 kana characters are excluded from the initial release pool (they are listed above for completeness only)
- Katakana loanwords that are the primary form (e.g., パン, コーヒー) appear only in Katakana sessions or Mixed sessions
- Native Japanese words listed with hiragana appear in Hiragana or Mixed sessions
- Some words have both hiragana and katakana forms — in Mixed sessions both may appear as separate entries

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
