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

    // SM-2 spaced repetition — Recognition (typeA)
    var typeAIntervalDays: Int
    var typeAEaseFactor: Double
    var typeAConsecutiveCorrect: Int
    var typeANextReviewDate: Date?

    // SM-2 spaced repetition — Production (typeB)
    var typeBIntervalDays: Int
    var typeBEaseFactor: Double
    var typeBConsecutiveCorrect: Int
    var typeBNextReviewDate: Date?

    init(characterId: String) {
        self.characterId = characterId
        self.correctCount = 0
        self.incorrectCount = 0
        self.lastPracticed = nil
        self.typeACorrect = 0
        self.typeAIncorrect = 0
        self.typeBCorrect = 0
        self.typeBIncorrect = 0
        self.typeAIntervalDays = 1
        self.typeAEaseFactor = 2.5
        self.typeAConsecutiveCorrect = 0
        self.typeANextReviewDate = nil
        self.typeBIntervalDays = 1
        self.typeBEaseFactor = 2.5
        self.typeBConsecutiveCorrect = 0
        self.typeBNextReviewDate = nil
    }

    // Combined totals (for overall display in CharacterDetailView)
    var totalCount: Int { correctCount + incorrectCount }

    var accuracy: Double {
        totalCount > 0 ? Double(correctCount) / Double(totalCount) : 0.0
    }

    // MARK: - Per-type accuracy

    var typeAAccuracy: Double {
        let total = typeACorrect + typeAIncorrect
        return total > 0 ? Double(typeACorrect) / Double(total) : 0.0
    }

    var typeBAccuracy: Double {
        let total = typeBCorrect + typeBIncorrect
        return total > 0 ? Double(typeBCorrect) / Double(total) : 0.0
    }

    // MARK: - Per-type strength (0.0 weak → 1.0 strong)

    var typeAStrength: Double {
        let total = typeACorrect + typeAIncorrect
        guard total > 0 else { return 0 }
        let confidence = min(Double(total) / 10.0, 1.0)
        return typeAAccuracy * confidence
    }

    var typeBStrength: Double {
        let total = typeBCorrect + typeBIncorrect
        guard total > 0 else { return 0 }
        let confidence = min(Double(total) / 10.0, 1.0)
        return typeBAccuracy * confidence
    }

    // MARK: - Per-type isDue (only true when the type has been attempted)

    var typeAIsDue: Bool {
        let attempted = typeACorrect + typeAIncorrect > 0
        guard let next = typeANextReviewDate else { return attempted }
        return next <= Date()
    }

    var typeBIsDue: Bool {
        let attempted = typeBCorrect + typeBIncorrect > 0
        guard let next = typeBNextReviewDate else { return attempted }
        return next <= Date()
    }

    // MARK: - Per-type mastery level

    var typeAMasteryLevel: MasteryLevel {
        let total = typeACorrect + typeAIncorrect
        if total == 0                    { return .new }
        if typeAConsecutiveCorrect < 2   { return .learning }
        if typeAIntervalDays < 21        { return .reviewing }
        return .mastered
    }

    var typeBMasteryLevel: MasteryLevel {
        let total = typeBCorrect + typeBIncorrect
        if total == 0                    { return .new }
        if typeBConsecutiveCorrect < 2   { return .learning }
        if typeBIntervalDays < 21        { return .reviewing }
        return .mastered
    }
}
