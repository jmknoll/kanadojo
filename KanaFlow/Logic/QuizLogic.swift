import Foundation

// MARK: - Answer Validation

func validateAnswer(_ character: KanaCharacter, answer: String) -> Bool {
    let normalized = answer.lowercased().trimmingCharacters(in: .whitespaces)
    if normalized == character.romaji.lowercased() { return true }
    return character.alternateRomaji.contains { $0.lowercased() == normalized }
}

// MARK: - Shuffle

func shuffleArray<T>(_ array: [T]) -> [T] {
    var shuffled = array
    for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
        let j = Int.random(in: 0...i)
        shuffled.swapAt(i, j)
    }
    return shuffled
}

// MARK: - Stats

func calculateStats(_ results: [QuizResult]) -> QuizStats {
    let total = results.count
    let correct = results.filter { $0.correct }.count
    let incorrect = total - correct
    let percentage = total > 0 ? Int((Double(correct) / Double(total)) * 100) : 0
    return QuizStats(total: total, correct: correct, incorrect: incorrect, percentage: percentage)
}
