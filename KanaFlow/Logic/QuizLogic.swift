import Foundation
import SwiftData

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

// MARK: - Spaced Repetition (SM-2)

func applySpacedRepetition(to progress: CharacterProgress, correct: Bool, quizType: QuizType) {
    switch quizType {
    case .typeA:
        if correct {
            switch progress.typeAConsecutiveCorrect {
            case 0:  progress.typeAIntervalDays = 1
            case 1:  progress.typeAIntervalDays = 6
            default: progress.typeAIntervalDays = Int((Double(progress.typeAIntervalDays) * progress.typeAEaseFactor).rounded())
            }
            progress.typeAEaseFactor = max(1.3, progress.typeAEaseFactor + 0.1)
            progress.typeAConsecutiveCorrect += 1
        } else {
            progress.typeAConsecutiveCorrect = 0
            progress.typeAIntervalDays = 1
            progress.typeAEaseFactor = max(1.3, progress.typeAEaseFactor - 0.2)
        }
        progress.typeANextReviewDate = Calendar.current.date(
            byAdding: .day, value: progress.typeAIntervalDays, to: Date()
        )

    case .typeB:
        if correct {
            switch progress.typeBConsecutiveCorrect {
            case 0:  progress.typeBIntervalDays = 1
            case 1:  progress.typeBIntervalDays = 6
            default: progress.typeBIntervalDays = Int((Double(progress.typeBIntervalDays) * progress.typeBEaseFactor).rounded())
            }
            progress.typeBEaseFactor = max(1.3, progress.typeBEaseFactor + 0.1)
            progress.typeBConsecutiveCorrect += 1
        } else {
            progress.typeBConsecutiveCorrect = 0
            progress.typeBIntervalDays = 1
            progress.typeBEaseFactor = max(1.3, progress.typeBEaseFactor - 0.2)
        }
        progress.typeBNextReviewDate = Calendar.current.date(
            byAdding: .day, value: progress.typeBIntervalDays, to: Date()
        )
    }
}

// MARK: - Weighted Sample
//
// Selects `count` characters from `pool` without replacement using weighted
// random sampling. Characters with lower strength have higher selection probability.
//
// weightFloor controls the minimum weight for strong characters:
//   Full Practice — 0.1: mastered chars still appear occasionally
//   Struggling    — 0.01: heavy bias toward weakest, but still non-deterministic

func weightedSample(
    _ pool: [KanaCharacter],
    count: Int,
    progressDict: [String: CharacterProgress],
    weightFloor: Double,
    quizType: QuizType
) -> [KanaCharacter] {
    guard !pool.isEmpty else { return [] }
    let n = min(count, pool.count)

    var remaining = pool
    var result: [KanaCharacter] = []

    while result.count < n && !remaining.isEmpty {
        let weights = remaining.map { char -> Double in
            let strength: Double
            switch quizType {
            case .typeA: strength = progressDict[char.id]?.typeAStrength ?? 0
            case .typeB: strength = progressDict[char.id]?.typeBStrength ?? 0
            }
            return max(weightFloor, 1.0 - strength)
        }
        let totalWeight = weights.reduce(0, +)
        let roll = Double.random(in: 0..<totalWeight)

        var cumulative = 0.0
        var selectedIndex = remaining.count - 1
        for (i, w) in weights.enumerated() {
            cumulative += w
            if roll < cumulative {
                selectedIndex = i
                break
            }
        }

        result.append(remaining[selectedIndex])
        remaining.remove(at: selectedIndex)
    }

    return result
}

// MARK: - Stats

func calculateStats(_ results: [QuizResult]) -> QuizStats {
    let total = results.count
    let correct = results.filter { $0.correct }.count
    let incorrect = total - correct
    let percentage = total > 0 ? Int((Double(correct) / Double(total)) * 100) : 0
    return QuizStats(total: total, correct: correct, incorrect: incorrect, percentage: percentage)
}
