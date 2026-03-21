import Foundation

enum WordQuizState {
    case prompt      // show English + romaji; waiting for user to tap "Start Writing"
    case drawing     // canvas active
    case grading     // grading overlay visible
    case complete    // session finished
}

@Observable
final class WordQuizViewModel {
    var state: WordQuizState = .prompt
    var words: [WordEntry] = []
    var currentIndex: Int = 0
    var results: [(word: WordEntry, kana: String, correct: Bool)] = []
    var submittedStrokes: [Stroke] = []
    var hintUsed: Bool = false

    private var scriptType: WordScriptType = .hiragana

    var currentWord: WordEntry? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    var currentKana: String {
        currentWord?.kana(for: scriptType) ?? ""
    }

    var progress: Double {
        words.isEmpty ? 0 : Double(currentIndex) / Double(words.count)
    }

    // MARK: - Load

    func load(config: WordQuizConfig) {
        words = config.wordPool
        scriptType = config.scriptType
        currentIndex = 0
        results = []
        hintUsed = false
        submittedStrokes = []
        state = words.isEmpty ? .complete : .prompt
    }

    // MARK: - Transitions

    @MainActor
    func startDrawing() {
        state = .drawing
    }

    @MainActor
    func submitDrawing(_ strokes: [Stroke]) {
        submittedStrokes = strokes
        state = .grading
    }

    @MainActor
    func submitGrade(_ wasCorrect: Bool, store: WordProgressStore) {
        guard let word = currentWord else { return }
        let effective = hintUsed ? false : wasCorrect
        results.append((word: word, kana: currentKana, correct: effective))
        store.updateProgress(wordID: word.id, correct: effective)
        advance()
    }

    func recordHintUsed() {
        hintUsed = true
    }

    // MARK: - Private

    private func advance() {
        hintUsed = false
        submittedStrokes = []
        let next = currentIndex + 1
        if next >= words.count {
            state = .complete
        } else {
            currentIndex = next
            state = .prompt
        }
    }
}
