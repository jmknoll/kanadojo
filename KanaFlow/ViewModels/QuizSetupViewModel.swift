import Foundation
import SwiftData

@Observable
final class QuizSetupViewModel {
    var kanaType: KanaTypeSelection = .hiragana
    var group: GroupSelection = .all
    var quizType: QuizType = .typeA
    var practiceMode: PracticeMode = .full
    var questionCount: QuestionCount = .ten

    var strugglingCount: Int = 0
    var isLoadingStruggling: Bool = false

    var availableCount: Int {
        let chars = KanaData.getCharacters(kanaType: kanaType, group: group)
        if practiceMode == .struggling {
            return min(strugglingCount, questionCount == .all ? Int.max : questionCount.rawValue)
        }
        if questionCount == .all { return chars.count }
        return min(chars.count, questionCount.rawValue)
    }

    var canStart: Bool {
        if practiceMode == .struggling { return strugglingCount > 0 }
        return KanaData.getCharacters(kanaType: kanaType, group: group).count > 0
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
            questionCount: questionCount
        )
    }

    @MainActor
    func refreshStrugglingCount(store: ProgressStore) async {
        isLoadingStruggling = true
        strugglingCount = store.getStrugglingIds(kanaType: kanaType, group: group, quizType: quizType).count
        isLoadingStruggling = false
    }
}
