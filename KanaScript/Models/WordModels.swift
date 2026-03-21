import Foundation

// MARK: - Enums

enum WordCategory: String, CaseIterable, Codable {
    case foodAndDrink  = "Food & Drink"
    case body          = "Body"
    case timeCalendar  = "Time & Calendar"
    case people        = "People"
    case nature        = "Nature"
    case places        = "Places"
    case dailyLife     = "Daily Life"
    case adjectives    = "Adjectives"
    case verbs         = "Verbs"
    case other         = "Other"
}

enum WordScriptType: String, CaseIterable, Codable {
    case hiragana
    case katakana
    case mixed

    var displayName: String {
        switch self {
        case .hiragana: return "Hiragana"
        case .katakana: return "Katakana"
        case .mixed:    return "Mixed"
        }
    }
}

enum WordSessionLength: Int, CaseIterable, Codable {
    case ten    = 10
    case twenty = 20
    case thirty = 30

    var displayName: String { "\(rawValue)" }
}

// MARK: - WordEntry

struct WordEntry: Identifiable {
    let id: String          // stable slug, e.g. "gohan"
    let hiragana: String    // empty string if no hiragana form (loanword)
    let katakana: String    // empty string if no natural katakana form
    let romaji: String
    let english: String
    let category: WordCategory

    /// Returns the kana string to display for a given script type session.
    /// Returns nil if this entry has no form for the requested script type.
    func kana(for scriptType: WordScriptType) -> String? {
        switch scriptType {
        case .hiragana: return hiragana.isEmpty ? nil : hiragana
        case .katakana: return katakana.isEmpty ? nil : katakana
        case .mixed:    return hiragana.isEmpty ? (katakana.isEmpty ? nil : katakana) : hiragana
        }
    }
}

// MARK: - WordQuizConfig

struct WordQuizConfig {
    let scriptType: WordScriptType
    let selectedCategories: [WordCategory]  // empty = all categories
    let sessionLength: WordSessionLength
    let wordPool: [WordEntry]               // pre-built weighted pool
}

extension WordQuizConfig: Hashable {
    static func == (lhs: WordQuizConfig, rhs: WordQuizConfig) -> Bool {
        lhs.scriptType == rhs.scriptType &&
        lhs.selectedCategories == rhs.selectedCategories &&
        lhs.sessionLength == rhs.sessionLength &&
        lhs.wordPool.map(\.id) == rhs.wordPool.map(\.id)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(scriptType.rawValue)
        hasher.combine(selectedCategories.map(\.rawValue))
        hasher.combine(sessionLength.rawValue)
        hasher.combine(wordPool.map(\.id))
    }
}
