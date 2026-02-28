import Foundation
import SwiftData

@Model
final class CharacterProgress {
    @Attribute(.unique) var characterId: String
    var correctCount: Int
    var incorrectCount: Int
    var lastPracticed: Date?
    var typeACorrect: Int
    var typeAIncorrect: Int
    var typeBCorrect: Int
    var typeBIncorrect: Int

    // SM-2 spaced repetition fields
    var intervalDays: Int        // days until next review
    var easeFactor: Double       // SM-2 ease multiplier
    var consecutiveCorrect: Int  // current correct streak
    var nextReviewDate: Date?    // nil = never reviewed, always due

    init(characterId: String) {
        self.characterId = characterId
        self.correctCount = 0
        self.incorrectCount = 0
        self.lastPracticed = nil
        self.typeACorrect = 0
        self.typeAIncorrect = 0
        self.typeBCorrect = 0
        self.typeBIncorrect = 0
        self.intervalDays = 1
        self.easeFactor = 2.5
        self.consecutiveCorrect = 0
        self.nextReviewDate = nil
    }

    var totalCount: Int { correctCount + incorrectCount }

    var accuracy: Double {
        totalCount > 0 ? Double(correctCount) / Double(totalCount) : 0.0
    }

    // 0.0 (unknown/weak) → 1.0 (strong). Scales with attempt count so
    // 1 lucky correct answer doesn't inflate the score.
    var strength: Double {
        guard totalCount > 0 else { return 0 }
        let confidence = min(Double(totalCount) / 10.0, 1.0)
        return accuracy * confidence
    }

    // True when the character is due for review today or earlier
    var isDue: Bool {
        guard let next = nextReviewDate else { return true }
        return next <= Date()
    }

    var masteryLevel: MasteryLevel {
        if totalCount == 0     { return .new }
        if consecutiveCorrect < 2 { return .learning }
        if intervalDays < 21   { return .reviewing }
        return .mastered
    }
}
