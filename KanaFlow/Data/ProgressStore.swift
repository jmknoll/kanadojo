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

        applySpacedRepetition(to: progress, correct: correct, quizType: quizType)
        StreakStore.shared.recordStudyToday()

        try? context.save()
    }

    // MARK: - Struggling Characters
    //
    // A character is "struggling" if it is due for review OR has been attempted
    // with accuracy below 70% — evaluated per quiz type.

    func getStrugglingIds(kanaType: KanaTypeSelection, group: GroupSelection, quizType: QuizType) -> [String] {
        let descriptor = FetchDescriptor<CharacterProgress>()
        guard let all = try? context.fetch(descriptor) else { return [] }

        let validIds = Set(KanaData.getCharacters(kanaType: kanaType, group: group).map { $0.id })

        return all
            .filter { validIds.contains($0.characterId) }
            .filter { progress in
                switch quizType {
                case .typeA:
                    let attempted = progress.typeACorrect + progress.typeAIncorrect > 0
                    return attempted && (progress.typeAIsDue || progress.typeAAccuracy < 0.7)
                case .typeB:
                    let attempted = progress.typeBCorrect + progress.typeBIncorrect > 0
                    return attempted && (progress.typeBIsDue || progress.typeBAccuracy < 0.7)
                }
            }
            .map { $0.characterId }
    }

    // MARK: - All Progress Dictionary

    func allProgressDict() -> [String: CharacterProgress] {
        let descriptor = FetchDescriptor<CharacterProgress>()
        guard let all = try? context.fetch(descriptor) else { return [:] }
        return Dictionary(uniqueKeysWithValues: all.map { ($0.characterId, $0) })
    }

    // MARK: - Single Character Lookup

    func progressFor(characterId: String) -> CharacterProgress? {
        let descriptor = FetchDescriptor<CharacterProgress>(
            predicate: #Predicate { $0.characterId == characterId }
        )
        return (try? context.fetch(descriptor))?.first
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
