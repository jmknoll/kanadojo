import SwiftUI
import SwiftData

struct StatsView: View {
    @Binding var path: NavigationPath
    @Query private var allProgress: [CharacterProgress]
    @Query private var allWordProgress: [WordProgress]

    @State private var selectedType: QuizType = .typeA
    @State private var selectedKanaType: KanaType? = nil  // nil = All
    @State private var expandedLevels: Set<MasteryLevel> = []

    // MARK: - Filtered data

    /// KanaCharacter lookup keyed by characterId
    private var charDict: [String: KanaCharacter] {
        Dictionary(uniqueKeysWithValues: KanaData.allCharacters.map { ($0.id, $0) })
    }

    /// Character IDs for the selected kana type (nil = all)
    private var filteredIds: Set<String> {
        guard let kt = selectedKanaType else { return Set(charDict.keys) }
        return Set(KanaData.allCharacters.filter { $0.type == kt }.map { $0.id })
    }

    private var filteredProgress: [CharacterProgress] {
        let ids = filteredIds
        return allProgress.filter { ids.contains($0.characterId) }
    }

    private var totalKana: Int { filteredIds.count }

    // MARK: - Derived data

    private var practiced: [CharacterProgress] {
        switch selectedType {
        case .typeA: return filteredProgress.filter { $0.typeACorrect + $0.typeAIncorrect > 0 }
        case .typeB: return filteredProgress.filter { $0.typeBCorrect + $0.typeBIncorrect > 0 }
        }
    }

    private var overallAccuracy: Int {
        switch selectedType {
        case .typeA:
            let total = practiced.reduce(0) { $0 + $1.typeACorrect + $1.typeAIncorrect }
            let correct = practiced.reduce(0) { $0 + $1.typeACorrect }
            guard total > 0 else { return 0 }
            return Int(Double(correct) / Double(total) * 100)
        case .typeB:
            let total = practiced.reduce(0) { $0 + $1.typeBCorrect + $1.typeBIncorrect }
            let correct = practiced.reduce(0) { $0 + $1.typeBCorrect }
            guard total > 0 else { return 0 }
            return Int(Double(correct) / Double(total) * 100)
        }
    }

    private var masteryBreakdown: [(level: MasteryLevel, count: Int)] {
        let counts: [MasteryLevel: [CharacterProgress]]
        switch selectedType {
        case .typeA: counts = Dictionary(grouping: filteredProgress) { $0.typeAMasteryLevel }
        case .typeB: counts = Dictionary(grouping: filteredProgress) { $0.typeBMasteryLevel }
        }
        return MasteryLevel.allCases.map { level in
            (level: level, count: counts[level]?.count ?? 0)
        }
    }

    private var needsPractice: [(character: KanaCharacter, progress: CharacterProgress)] {
        let d = charDict
        let filtered: [CharacterProgress]
        switch selectedType {
        case .typeA:
            filtered = filteredProgress
                .filter {
                    let attempted = $0.typeACorrect + $0.typeAIncorrect > 0
                    return attempted && ($0.typeAIsDue || $0.typeAAccuracy < 0.7)
                }
                .sorted { $0.typeAStrength < $1.typeAStrength }
        case .typeB:
            filtered = filteredProgress
                .filter {
                    let attempted = $0.typeBCorrect + $0.typeBIncorrect > 0
                    return attempted && ($0.typeBIsDue || $0.typeBAccuracy < 0.7)
                }
                .sorted { $0.typeBStrength < $1.typeBStrength }
        }
        return filtered.compactMap { prog in
            guard let char = d[prog.characterId] else { return nil }
            return (character: char, progress: prog)
        }
    }

    /// Characters at a given mastery level for the current quiz type filter.
    private func characters(at level: MasteryLevel) -> [KanaCharacter] {
        let d = charDict
        let ids = filteredIds
        let progressById = Dictionary(uniqueKeysWithValues: filteredProgress.map { ($0.characterId, $0) })

        return ids.compactMap { id -> KanaCharacter? in
            guard let char = d[id] else { return nil }
            let prog = progressById[id]
            let charLevel: MasteryLevel
            switch selectedType {
            case .typeA: charLevel = prog?.typeAMasteryLevel ?? .new
            case .typeB: charLevel = prog?.typeBMasteryLevel ?? .new
            }
            return charLevel == level ? char : nil
        }
        .sorted { $0.romaji < $1.romaji }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                // Kana type filter
                Picker("Kana Type", selection: $selectedKanaType) {
                    Text("All").tag(Optional<KanaType>.none)
                    Text("Hiragana").tag(Optional<KanaType>.some(.hiragana))
                    Text("Katakana").tag(Optional<KanaType>.some(.katakana))
                }
                .pickerStyle(.segmented)

                // Quiz type filter
                Picker("Quiz Type", selection: $selectedType) {
                    Text("Recognition").tag(QuizType.typeA)
                    Text("Production").tag(QuizType.typeB)
                }
                .pickerStyle(.segmented)

                summaryStrip
                masterySection
                characterBrowserSection
                needsPracticeSection
                wordStatsSection
            }
            .padding(AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxxl)
            .adaptiveTopPadding()
            .adaptiveContentWidth()
        }
        .background(AppColors.background)
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary strip

    private var summaryStrip: some View {
        HStack(spacing: AppSpacing.sm) {
            summaryCard(
                value: streakLabel,
                label: "Streak",
                color: StreakStore.shared.currentStreak > 0 ? AppColors.warning : AppColors.textMuted
            )
            summaryCard(
                value: "\(practiced.count)/\(totalKana)",
                label: "Practiced",
                color: AppColors.tint
            )
            summaryCard(
                value: practiced.isEmpty ? "—" : "\(overallAccuracy)%",
                label: "Accuracy",
                color: overallAccuracy >= 70 ? AppColors.success : AppColors.error
            )
        }
    }

    private var streakLabel: String {
        let n = StreakStore.shared.currentStreak
        return n == 0 ? "—" : "\(n) day\(n == 1 ? "" : "s")"
    }

    private func summaryCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppFonts.heading2)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Mastery breakdown

    private var masterySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Mastery")
                .font(AppFonts.heading3)
                .foregroundStyle(AppColors.text)

            VStack(spacing: AppSpacing.sm) {
                ForEach(masteryBreakdown, id: \.level) { item in
                    masteryRow(level: item.level, count: item.count)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
    }

    private func masteryRow(level: MasteryLevel, count: Int) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(level.color)
                .frame(width: 10, height: 10)

            Text(level.displayName)
                .font(AppFonts.label)
                .foregroundStyle(AppColors.text)
                .frame(width: 76, alignment: .leading)

            Text("\(count)")
                .font(AppFonts.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 28, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.backgroundSecondary)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(level.color)
                        .frame(width: geo.size.width * min(Double(count) / Double(totalKana), 1.0))
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Character Browser

    private var characterBrowserSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Characters")
                .font(AppFonts.heading3)
                .foregroundStyle(AppColors.text)

            VStack(spacing: 0) {
                ForEach(MasteryLevel.allCases, id: \.self) { level in
                    let chars = characters(at: level)
                    if !chars.isEmpty {
                        browserLevelRow(level: level, chars: chars)
                        if level != MasteryLevel.allCases.last {
                            Divider().padding(.horizontal, AppSpacing.md)
                        }
                    }
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
    }

    private func browserLevelRow(level: MasteryLevel, chars: [KanaCharacter]) -> some View {
        let isExpanded = expandedLevels.contains(level)
        return VStack(spacing: 0) {
            Button {
                if isExpanded {
                    expandedLevels.remove(level)
                } else {
                    expandedLevels.insert(level)
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Circle()
                        .fill(level.color)
                        .frame(width: 10, height: 10)
                    Text(level.displayName)
                        .font(AppFonts.label)
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Text("\(chars.count)")
                        .font(AppFonts.captionBold)
                        .foregroundStyle(AppColors.textMuted)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textMuted)
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(.plain)

            if isExpanded {
                let columns = [GridItem(.adaptive(minimum: 52), spacing: AppSpacing.sm)]
                LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                    ForEach(chars, id: \.id) { char in
                        Button {
                            path.append(AppDestination.characterDetail(character: char))
                        } label: {
                            VStack(spacing: 2) {
                                Text(char.character)
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(AppColors.text)
                                Text(char.romaji)
                                    .font(AppFonts.small)
                                    .foregroundStyle(AppColors.textMuted)
                            }
                            .frame(width: 52, height: 52)
                            .background(AppColors.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .stroke(level.color.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppSpacing.md)
                .padding(.top, 0)
            }
        }
    }

    // MARK: - Needs Practice

    @ViewBuilder
    private var needsPracticeSection: some View {
        let items = needsPractice
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Needs Practice")
                .font(AppFonts.heading3)
                .foregroundStyle(AppColors.text)

            if items.isEmpty {
                emptyPracticeState
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(items, id: \.character.id) { item in
                        needsPracticeRow(item.character, item.progress)
                    }
                }
            }
        }
    }

    private var emptyPracticeState: some View {
        let hasPracticed = !practiced.isEmpty
        return Text(hasPracticed
            ? "All caught up! Keep practicing to maintain mastery."
            : "Complete a quiz to see your weak characters here.")
            .font(AppFonts.body)
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
    }

    // MARK: - Word Stats

    @ViewBuilder
    private var wordStatsSection: some View {
        let practiced = allWordProgress.filter { $0.totalCount > 0 }
        let totalAttempts = practiced.reduce(0) { $0 + $1.totalCount }
        let totalCorrect = practiced.reduce(0) { $0 + $1.correctCount }
        let wordAccuracy = totalAttempts > 0 ? Int(Double(totalCorrect) / Double(totalAttempts) * 100) : 0
        let wordDict = Dictionary(uniqueKeysWithValues: allWordProgress.map { ($0.wordID, $0) })

        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Word Writing")
                .font(AppFonts.heading3)
                .foregroundStyle(AppColors.text)

            if practiced.isEmpty {
                Text("Complete a word writing session to see your progress here.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.lg)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(AppColors.cardBorder, lineWidth: 1))
            } else {
                // Summary chips
                HStack(spacing: AppSpacing.sm) {
                    wordSummaryCard(value: "\(practiced.count)", label: "Practiced", color: AppColors.tint)
                    wordSummaryCard(value: "\(wordAccuracy)%", label: "Accuracy", color: wordAccuracy >= 70 ? AppColors.success : AppColors.error)
                }

                // Word list (collapsed, sorted by strength ascending)
                let sortedWords = WordData.allWords
                    .compactMap { entry -> (entry: WordEntry, progress: WordProgress)? in
                        guard let prog = wordDict[entry.id], prog.totalCount > 0 else { return nil }
                        return (entry: entry, progress: prog)
                    }
                    .sorted { $0.progress.strength < $1.progress.strength }

                VStack(spacing: AppSpacing.sm) {
                    ForEach(sortedWords.prefix(10), id: \.entry.id) { item in
                        wordProgressRow(item.entry, item.progress)
                    }
                    if sortedWords.count > 10 {
                        Text("+ \(sortedWords.count - 10) more words practiced")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, AppSpacing.xs)
                    }
                }
            }
        }
    }

    private func wordSummaryCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppFonts.heading2)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.cardBorder, lineWidth: 1))
    }

    private func wordProgressRow(_ entry: WordEntry, _ progress: WordProgress) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Kana display — prefer hiragana, fall back to katakana
            let displayKana = entry.hiragana.isEmpty ? entry.katakana : entry.hiragana
            Text(displayKana)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(AppColors.text)
                .frame(width: 72, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.romaji)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.text)
                Text(entry.english)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()

            Text("\(Int(progress.accuracy * 100))%")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(progress.accuracy >= 0.7 ? AppColors.success : AppColors.error)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.cardBorder, lineWidth: 0.5))
    }

    private func needsPracticeRow(_ char: KanaCharacter, _ progress: CharacterProgress) -> some View {
        let isDue: Bool
        let accuracy: Double
        let masteryLevel: MasteryLevel
        switch selectedType {
        case .typeA:
            isDue = progress.typeAIsDue
            accuracy = progress.typeAAccuracy
            masteryLevel = progress.typeAMasteryLevel
        case .typeB:
            isDue = progress.typeBIsDue
            accuracy = progress.typeBAccuracy
            masteryLevel = progress.typeBMasteryLevel
        }

        return Button {
            path.append(AppDestination.characterDetail(character: char))
        } label: {
            HStack(spacing: AppSpacing.md) {
                Text(char.character)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppColors.text)
                    .frame(width: 44, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(char.romaji)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.text)
                    MasteryBadge(level: masteryLevel)
                }

                Spacer()

                if isDue {
                    Text("Due")
                        .font(AppFonts.small)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 2)
                        .background(AppColors.warning)
                        .clipShape(Capsule())
                }

                Text("\(Int(accuracy * 100))%")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(accuracy >= 0.7 ? AppColors.success : AppColors.error)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.cardBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
