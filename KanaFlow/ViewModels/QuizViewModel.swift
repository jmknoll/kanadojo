import Foundation

typealias Point = CGPoint
typealias Stroke = [Point]

enum QuizState {
    case loading
    case playing
    case feedback
    case selfGrading
    case complete
}

@Observable
final class QuizViewModel {
    var state: QuizState = .loading
    var characters: [KanaCharacter] = []
    var currentIndex: Int = 0
    var results: [QuizResult] = []
    var lastAnswerCorrect: Bool? = nil
    var submittedStrokes: [Stroke] = []
    var hintUsedThisQuestion: Bool = false

    var currentCharacter: KanaCharacter? {
        guard currentIndex < characters.count else { return nil }
        return characters[currentIndex]
    }

    var progress: Double {
        characters.isEmpty ? 0 : Double(currentIndex) / Double(characters.count)
    }

    var stats: QuizStats {
        calculateStats(results)
    }

    // MARK: - Load

    @MainActor
    func load(config: QuizConfig, store: ProgressStore) async {
        state = .loading

        var pool = KanaData.getCharacters(kanaType: config.kanaType, group: config.group)

        if config.practiceMode == .struggling {
            let strugglingIds = Set(store.getStrugglingIds(kanaType: config.kanaType, group: config.group))
            pool = pool.filter { strugglingIds.contains($0.id) }
        }

        pool = shuffleArray(pool)

        if config.questionCount != .all {
            pool = Array(pool.prefix(config.questionCount.rawValue))
        }

        characters = pool
        currentIndex = 0
        results = []
        hintUsedThisQuestion = false
        state = characters.isEmpty ? .complete : .playing
    }

    // MARK: - Type A: Submit Answer

    @MainActor
    func submitAnswer(_ answer: String, store: ProgressStore) {
        guard let char = currentCharacter else { return }
        let correct = validateAnswer(char, answer: answer)
        let result = QuizResult(character: char, userAnswer: answer, correct: correct)
        results.append(result)
        lastAnswerCorrect = correct
        store.updateProgress(characterId: char.id, correct: correct, quizType: .typeA)
        state = .feedback

        if correct {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(800))
                nextQuestion()
            }
        }
    }

    // MARK: - Type B: Submit Drawing

    func submitDrawing(_ strokes: [Stroke]) {
        submittedStrokes = strokes
        state = .selfGrading
    }

    // MARK: - Type B: Self Grade

    @MainActor
    func submitSelfGrade(_ wasCorrect: Bool, store: ProgressStore) {
        guard let char = currentCharacter else { return }
        let effectiveCorrect = hintUsedThisQuestion ? false : wasCorrect
        let result = QuizResult(character: char, userAnswer: "", correct: effectiveCorrect)
        results.append(result)
        lastAnswerCorrect = effectiveCorrect
        store.updateProgress(characterId: char.id, correct: effectiveCorrect, quizType: .typeB)
        nextQuestion()
    }

    // MARK: - Navigation

    func nextQuestion() {
        hintUsedThisQuestion = false
        submittedStrokes = []
        let next = currentIndex + 1
        if next >= characters.count {
            state = .complete
        } else {
            currentIndex = next
            lastAnswerCorrect = nil
            state = .playing
        }
    }

    // MARK: - Hint

    func recordHintUsed() {
        hintUsedThisQuestion = true
    }
}
