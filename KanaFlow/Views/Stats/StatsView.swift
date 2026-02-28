import SwiftUI
import SwiftData

struct StatsView: View {
    @Binding var path: NavigationPath
    @Query private var allProgress: [CharacterProgress]

    private let totalKana = KanaData.allCharacters.count  // 214

    // MARK: - Derived data

    private var practiced: [CharacterProgress] {
        allProgress.filter { $0.totalCount > 0 }
    }

    private var overallAccuracy: Int {
        let total = practiced.reduce(0) { $0 + $1.totalCount }
        let correct = practiced.reduce(0) { $0 + $1.correctCount }
        guard total > 0 else { return 0 }
        return Int(Double(correct) / Double(total) * 100)
    }

    private var masteryBreakdown: [(level: MasteryLevel, count: Int)] {
        let counts = Dictionary(grouping: allProgress) { $0.masteryLevel }
        return MasteryLevel.allCases.map { level in
            (level: level, count: counts[level]?.count ?? 0)
        }
    }

    private var needsPractice: [(character: KanaCharacter, progress: CharacterProgress)] {
        let charDict = Dictionary(uniqueKeysWithValues: KanaData.allCharacters.map { ($0.id, $0) })
        return allProgress
            .filter { $0.totalCount > 0 && ($0.isDue || $0.accuracy < 0.7) }
            .sorted { $0.strength < $1.strength }
            .compactMap { prog in
                guard let char = charDict[prog.characterId] else { return nil }
                return (character: char, progress: prog)
            }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                summaryStrip
                masterySection
                needsPracticeSection
            }
            .padding(AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxxl)
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

    private func needsPracticeRow(_ char: KanaCharacter, _ progress: CharacterProgress) -> some View {
        Button {
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
                    MasteryBadge(level: progress.masteryLevel)
                }

                Spacer()

                if progress.isDue {
                    Text("Due")
                        .font(AppFonts.small)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 2)
                        .background(AppColors.warning)
                        .clipShape(Capsule())
                }

                Text("\(Int(progress.accuracy * 100))%")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(progress.accuracy >= 0.7 ? AppColors.success : AppColors.error)

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
