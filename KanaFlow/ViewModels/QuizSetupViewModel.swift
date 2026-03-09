import Foundation
import SwiftData

@Observable
final class QuizSetupViewModel {
    var kanaType: KanaTypeSelection = .hiragana
    var group: GroupSelection = .all
    var quizType: QuizType = .typeA
    var practiceMode: PracticeMode = .full
    var questionCount: QuestionCount = .ten
    var selectedRows: Set<String> = []

    var strugglingCount: Int = 0
    var isLoadingStruggling: Bool = false

    var availableRows: [String] {
        KanaData.getAvailableRows(kanaType: kanaType, group: group)
    }

    private var filteredCharacters: [KanaCharacter] {
        KanaData.getCharacters(kanaType: kanaType, group: group, rows: Array(selectedRows))
    }

    var availableCount: Int {
        if practiceMode == .struggling {
            return min(strugglingCount, questionCount == .all ? Int.max : questionCount.rawValue)
        }
        let chars = filteredCharacters
        if questionCount == .all { return chars.count }
        return min(chars.count, questionCount.rawValue)
    }

    var canStart: Bool {
        if practiceMode == .struggling { return strugglingCount > 0 }
        return filteredCharacters.count > 0
    }

    var summaryText: String {
        let count = availableCount
        if count == 0 { return "No characters available" }
        if practiceMode == .struggling && strugglingCount == 0 {
            return "No struggling characters yet — try Full Practice first"
        }
        return "\(count) question\(count == 1 ? "" : "s")"
    }

    var config: QuizConfig {
        QuizConfig(
            kanaType: kanaType,
            group: group,
            quizType: quizType,
            practiceMode: practiceMode,
            questionCount: questionCount,
            selectedRows: Array(selectedRows)
        )
    }

    @MainActor
    func refreshStrugglingCount(store: ProgressStore) async {
        isLoadingStruggling = true
        strugglingCount = store.getStrugglingIds(kanaType: kanaType, group: group, quizType: quizType, rows: Array(selectedRows)).count
        isLoadingStruggling = false
    }
}
