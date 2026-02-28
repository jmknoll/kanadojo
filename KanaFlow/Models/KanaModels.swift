import Foundation

// MARK: - Enums

enum KanaType: String, Codable, CaseIterable {
    case hiragana
    case katakana
}

enum KanaGroup: String, Codable, CaseIterable {
    case main
    case dakuten
    case combination
}

enum KanaTypeSelection: String, CaseIterable {
    case hiragana
    case katakana
    case both

    var displayName: String {
        switch self {
        case .hiragana: return "Hiragana"
        case .katakana: return "Katakana"
        case .both: return "Both"
        }
    }
}

enum GroupSelection: String, CaseIterable {
    case all
    case main
    case dakuten
    case combination

    var displayName: String {
        switch self {
        case .all: return "All"
        case .main: return "Main"
        case .dakuten: return "Dakuten"
        case .combination: return "Combos"
        }
    }
}

enum PracticeMode: String, CaseIterable {
    case full
    case struggling

    var displayName: String {
        switch self {
        case .full: return "Full Practice"
        case .struggling: return "Struggling"
        }
    }

    var description: String {
        switch self {
        case .full: return "Practice all selected characters"
        case .struggling: return "Focus on characters you miss most"
        }
    }
}

enum QuizType: String, CaseIterable {
    case typeA  // Kana → Romaji (type the reading)
    case typeB  // Romaji → Kana (draw the character)

    var displayName: String {
        switch self {
        case .typeA: return "Type A"
        case .typeB: return "Type B"
        }
    }

    var description: String {
        switch self {
        case .typeA: return "See kana, type romaji"
        case .typeB: return "See romaji, draw kana"
        }
    }
}

enum QuestionCount: Int, CaseIterable {
    case ten = 10
    case twenty = 20
    case all = 0  // 0 = use all available

    var displayName: String {
        switch self {
        case .ten: return "10"
        case .twenty: return "20"
        case .all: return "All"
        }
    }
}

// MARK: - Models

struct KanaCharacter: Identifiable, Hashable {
    let id: String
    let character: String
    let romaji: String
    let alternateRomaji: [String]
    let type: KanaType
    let group: KanaGroup
    let row: String

    init(id: String, character: String, romaji: String,
         alternateRomaji: [String] = [], type: KanaType,
         group: KanaGroup, row: String) {
        self.id = id
        self.character = character
        self.romaji = romaji
        self.alternateRomaji = alternateRomaji
        self.type = type
        self.group = group
        self.row = row
    }
}

struct QuizResult {
    let character: KanaCharacter
    let userAnswer: String
    let correct: Bool
}

struct QuizStats {
    let total: Int
    let correct: Int
    let incorrect: Int
    let percentage: Int
}

struct QuizConfig {
    let kanaType: KanaTypeSelection
    let group: GroupSelection
    let quizType: QuizType
    let practiceMode: PracticeMode
    let questionCount: QuestionCount
}
