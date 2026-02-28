import SwiftUI
import SwiftData

enum AppDestination: Hashable {
    case quizSetup
    case quizPlay(config: QuizConfig)
    case study
    case characterDetail(character: KanaCharacter)
}

// QuizConfig needs to be Hashable for NavigationStack
extension QuizConfig: Hashable {
    static func == (lhs: QuizConfig, rhs: QuizConfig) -> Bool {
        lhs.kanaType == rhs.kanaType &&
        lhs.group == rhs.group &&
        lhs.quizType == rhs.quizType &&
        lhs.practiceMode == rhs.practiceMode &&
        lhs.questionCount == rhs.questionCount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(kanaType.rawValue)
        hasher.combine(group.rawValue)
        hasher.combine(quizType.rawValue)
        hasher.combine(practiceMode.rawValue)
        hasher.combine(questionCount.rawValue)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .quizSetup:
                        QuizSetupView(path: $path)
                    case .quizPlay(let config):
                        QuizPlayView(config: config, path: $path)
                    case .study:
                        StudyView(path: $path)
                    case .characterDetail(let character):
                        CharacterDetailView(character: character)
                    }
                }
        }
        .task {
            let store = ProgressStore(context: modelContext)
            store.initializeIfNeeded()
        }
    }
}
