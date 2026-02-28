import Foundation
import SwiftData

@MainActor
final class ProgressStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Update Progress

    func updateProgress(characterId: String, correct: Bool, quizType: QuizType) {
        let progress = fetchOrCreate(characterId: characterId)
        if correct {
            progress.correctCount += 1
        } else {
            progress.incorrectCount += 1
        }
        progress.lastPracticed = Date()

        switch quizType {
        case .typeA:
            if correct { progress.typeACorrect += 1 } else { progress.typeAIncorrect += 1 }
        case .typeB:
            if correct { progress.typeBCorrect += 1 } else { progress.typeBIncorrect += 1 }
        }

        try? context.save()
    }

    // MARK: - Struggling Characters

    func getStrugglingIds(kanaType: KanaTypeSelection, group: GroupSelection, threshold: Double = 0.6) -> [String] {
        let descriptor = FetchDescriptor<CharacterProgress>()
        guard let all = try? context.fetch(descriptor) else { return [] }

        // Get valid character ids for the selection
        let validChars = KanaData.getCharacters(kanaType: kanaType, group: group)
        let validIds = Set(validChars.map { $0.id })

        return all
            .filter { validIds.contains($0.characterId) }
            .filter { $0.totalCount > 0 && $0.accuracy < threshold }
            .map { $0.characterId }
    }

    // MARK: - Initialize

    func initializeIfNeeded() {
        let descriptor = FetchDescriptor<CharacterProgress>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingIds = Set(existing.map { $0.characterId })

        for char in KanaData.allCharacters {
            if !existingIds.contains(char.id) {
                context.insert(CharacterProgress(characterId: char.id))
            }
        }
        try? context.save()
    }

    // MARK: - Private Helpers

    private func fetchOrCreate(characterId: String) -> CharacterProgress {
        let descriptor = FetchDescriptor<CharacterProgress>(
            predicate: #Predicate { $0.characterId == characterId }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let new = CharacterProgress(characterId: characterId)
        context.insert(new)
        return new
    }
}
