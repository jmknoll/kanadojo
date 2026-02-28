import SwiftUI
import SwiftData

struct CharacterDetailView: View {
    let character: KanaCharacter

    @Query private var progressRecords: [CharacterProgress]

    private let canvasSize: CGFloat = 220
    @State private var revealedCount: Int = 0

    init(character: KanaCharacter) {
        self.character = character
        let id = character.id
        _progressRecords = Query(filter: #Predicate<CharacterProgress> { $0.characterId == id })
    }

    private var progress: CharacterProgress? { progressRecords.first }

    private var hintPaths: [Path] {
        strokePaths(for: character, in: canvasSize)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                headerSection
                strokeOrderSection
                if let p = progress, p.totalCount > 0 {
                    progressSection(p)
                }
            }
            .padding(AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .background(AppColors.background)
        .navigationTitle(character.character)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            revealedCount = hintPaths.count
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text(character.character)
                .font(AppFonts.kanaHuge)
                .foregroundStyle(AppColors.text)

            Text(character.romaji)
                .font(AppFonts.heading1)
                .foregroundStyle(AppColors.text)

            if !character.alternateRomaji.isEmpty {
                HStack(spacing: AppSpacing.sm) {
                    Text("also:")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                    ForEach(character.alternateRomaji, id: \.self) { alt in
                        Text(alt)
                            .font(AppFonts.captionBold)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 2)
                            .background(AppColors.backgroundSecondary)
                            .clipShape(Capsule())
                    }
                }
            }

            Text("\(character.type == .hiragana ? "Hiragana" : "Katakana") · \(groupDisplayName)")
                .font(AppFonts.small)
                .foregroundStyle(AppColors.tint)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.tint.opacity(0.12))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }

    private var groupDisplayName: String {
        switch character.group {
        case .main:        return "Main"
        case .dakuten:     return "Dakuten"
        case .combination: return "Combination"
        }
    }

    // MARK: - Stroke Order

    private var strokeOrderSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Stroke Order")
                .font(AppFonts.heading3)
                .foregroundStyle(AppColors.text)

            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )

                if hintPaths.isEmpty {
                    Text("No stroke data available")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                } else {
                    Canvas { context, _ in
                        for i in 0..<revealedCount where i < hintPaths.count {
                            context.stroke(
                                hintPaths[i],
                                with: .color(AppColors.text),
                                lineWidth: 3
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
            }
            .frame(width: canvasSize, height: canvasSize)
            .frame(maxWidth: .infinity)

            // Step-through controls
            HStack {
                Button("Reset") {
                    revealedCount = 0
                }
                .font(AppFonts.label)
                .foregroundStyle(revealedCount == 0 ? AppColors.textMuted : AppColors.textSecondary)
                .disabled(revealedCount == 0)

                Spacer()

                if !hintPaths.isEmpty {
                    Text("\(revealedCount) / \(hintPaths.count)")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Button("Next Stroke") {
                    if revealedCount < hintPaths.count {
                        revealedCount += 1
                    }
                }
                .font(AppFonts.label)
                .foregroundStyle(revealedCount >= hintPaths.count ? AppColors.textMuted : AppColors.tint)
                .disabled(revealedCount >= hintPaths.count)
            }
        }
    }

    // MARK: - Progress

    private func progressSection(_ p: CharacterProgress) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Your Progress")
                .font(AppFonts.heading3)
                .foregroundStyle(AppColors.text)

            HStack(spacing: 0) {
                statCell(
                    label: "Accuracy",
                    value: "\(Int(p.accuracy * 100))%",
                    color: p.accuracy >= 0.7 ? AppColors.success : AppColors.error
                )
                Divider()
                statCell(
                    label: "Type A",
                    value: "\(p.typeACorrect)/\(p.typeACorrect + p.typeAIncorrect)",
                    color: AppColors.textSecondary
                )
                Divider()
                statCell(
                    label: "Type B",
                    value: "\(p.typeBCorrect)/\(p.typeBCorrect + p.typeBIncorrect)",
                    color: AppColors.textSecondary
                )
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
    }

    private func statCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppFonts.heading2)
                .foregroundStyle(color)
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
    }
}
