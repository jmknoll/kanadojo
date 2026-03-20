import Foundation
import SwiftData

@Model
final class WordProgress {
    @Attribute(.unique) var wordID: String
    var correctCount: Int
    var incorrectCount: Int
    var lastPracticed: Date?

    // SM-2 spaced repetition fields
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

    // 0.0 (unknown/weak) → 1.0 (strong); mirrors CharacterProgress.strength formula
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
