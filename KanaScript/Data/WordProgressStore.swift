import Foundation
import SwiftData

@MainActor
final class WordProgressStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Update Progress

    func updateProgress(wordID: String, correct: Bool) {
        let progress = fetchOrCreate(wordID: wordID)
        if correct { progress.correctCount += 1 } else { progress.incorrectCount += 1 }
        progress.lastPracticed = Date()
        applyWordSpacedRepetition(to: progress, correct: correct)
        StreakStore.shared.recordStudyToday()
        try? context.save()
    }

    // MARK: - All Progress Dictionary

    func allProgressDict() -> [String: WordProgress] {
        let descriptor = FetchDescriptor<WordProgress>()
        guard let all = try? context.fetch(descriptor) else { return [:] }
        return Dictionary(uniqueKeysWithValues: all.map { ($0.wordID, $0) })
    }

    // MARK: - Build Session Pool

    /// Returns a weighted sample of `count` words from the filtered pool.
    /// Words with lower strength scores are more likely to be selected.
    func buildSessionPool(
        from words: [WordEntry],
        count: Int
    ) -> [WordEntry] {
        let progressDict = allProgressDict()
        return wordWeightedSample(words, count: count, progressDict: progressDict)
    }

    // MARK: - Private Helpers

    private func fetchOrCreate(wordID: String) -> WordProgress {
        let descriptor = FetchDescriptor<WordProgress>(
            predicate: #Predicate { $0.wordID == wordID }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let new = WordProgress(wordID: wordID)
        context.insert(new)
        return new
    }
}
