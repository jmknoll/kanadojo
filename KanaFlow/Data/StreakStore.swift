import Foundation

final class StreakStore {
    static let shared = StreakStore()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let currentStreak  = "streak.current"
        static let longestStreak  = "streak.longest"
        static let lastStudyDate  = "streak.lastStudyDate"
    }

    private init() {}

    var currentStreak: Int {
        get { defaults.integer(forKey: Keys.currentStreak) }
        set { defaults.set(newValue, forKey: Keys.currentStreak) }
    }

    var longestStreak: Int {
        get { defaults.integer(forKey: Keys.longestStreak) }
        set { defaults.set(newValue, forKey: Keys.longestStreak) }
    }

    var lastStudyDate: Date? {
        get { defaults.object(forKey: Keys.lastStudyDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastStudyDate) }
    }

    // Call once per answer recorded. Guards against duplicate updates within the same day.
    func recordStudyToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = lastStudyDate {
            let lastDay = calendar.startOfDay(for: last)

            if lastDay == today {
                // Already recorded today — update timestamp but don't change streak
                lastStudyDate = Date()
                return
            }

            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if lastDay == yesterday {
                currentStreak += 1
            } else {
                currentStreak = 1   // gap in days — reset
            }
        } else {
            currentStreak = 1       // first ever session
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        lastStudyDate = Date()
    }
}
