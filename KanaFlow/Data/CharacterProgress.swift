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

    init(characterId: String) {
        self.characterId = characterId
        self.correctCount = 0
        self.incorrectCount = 0
        self.lastPracticed = nil
        self.typeACorrect = 0
        self.typeAIncorrect = 0
        self.typeBCorrect = 0
        self.typeBIncorrect = 0
    }

    var totalCount: Int { correctCount + incorrectCount }

    var accuracy: Double {
        totalCount > 0 ? Double(correctCount) / Double(totalCount) : 1.0
    }
}
