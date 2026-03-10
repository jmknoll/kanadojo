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
    var mlScore: Float? = nil

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

        var pool = KanaData.getCharacters(kanaType: config.kanaType, group: config.group, rows: config.selectedRows)
        let progressDict = store.allProgressDict()

        if config.practiceMode == .struggling {
            let strugglingIds = Set(store.getStrugglingIds(kanaType: config.kanaType, group: config.group, quizType: config.quizType))
            pool = pool.filter { strugglingIds.contains($0.id) }
        }

        // Weighted sampling — weaker characters appear earlier with higher probability.
        // Struggling mode uses a lower floor (0.01) for a stronger bias toward weak chars.
        // Full Practice uses 0.1 so mastered characters still surface occasionally.
        let requestedCount = config.questionCount == .all ? pool.count : config.questionCount.rawValue
        let weightFloor: Double = config.practiceMode == .struggling ? 0.01 : 0.1

        characters = weightedSample(pool, count: requestedCount, progressDict: progressDict, weightFloor: weightFloor, quizType: config.quizType)
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

    /// Classify the user's drawing with the on-device ML model and transition to the grading overlay.
    @MainActor
    func submitDrawing(_ strokes: [Stroke], store: ProgressStore, canvasSize: CGFloat) {
        submittedStrokes = strokes
        if let char = currentCharacter {
            mlScore = KanaRecognizer.shared.classify(
                strokes: strokes,
                character: char,
                canvasSize: canvasSize
            )
        }
        state = .selfGrading
    }

    // MARK: - Type B: Confirm Grade

    /// Finalise the grade for the current Type B question.
    /// - Parameter wasCorrect: True when the ML score meets the passing threshold,
    ///   or the user self-grades as correct (fallback when model is unavailable).
    @MainActor
    func submitGrade(_ wasCorrect: Bool, store: ProgressStore) {
        guard let char = currentCharacter else { return }
        let effectiveCorrect = hintUsedThisQuestion ? false : wasCorrect
        let result = QuizResult(character: char, userAnswer: "", correct: effectiveCorrect)
        results.append(result)
        lastAnswerCorrect = effectiveCorrect
        store.updateProgress(characterId: char.id, correct: effectiveCorrect, quizType: .typeB, mlScore: mlScore)
        mlScore = nil
        nextQuestion()
    }

    // MARK: - Navigation

    func nextQuestion() {
        hintUsedThisQuestion = false
        submittedStrokes = []
        mlScore = nil
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
