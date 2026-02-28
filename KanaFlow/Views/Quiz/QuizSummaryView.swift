import SwiftUI

struct QuizSummaryView: View {
    let results: [QuizResult]
    let quizType: QuizType
    let onDone: () -> Void

    var stats: QuizStats { calculateStats(results) }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Score header
                VStack(spacing: AppSpacing.md) {
                    Text(scoreEmoji)
                        .font(.system(size: 64))

                    Text("\(stats.percentage)%")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(scoreColor)

                    Text("\(stats.correct) of \(stats.total) correct")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.top, AppSpacing.xxl)

                // Stats row
                HStack(spacing: 0) {
                    StatCell(label: "Correct", value: "\(stats.correct)", color: AppColors.success)
                    Divider()
                    StatCell(label: "Incorrect", value: "\(stats.incorrect)", color: AppColors.error)
                    Divider()
                    StatCell(label: "Total", value: "\(stats.total)", color: AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
                .padding(.horizontal, AppSpacing.lg)

                // Result list
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Results")
                        .font(AppFonts.heading3)
                        .foregroundStyle(AppColors.text)
                        .padding(.horizontal, AppSpacing.lg)

                    ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                        ResultRow(result: result, quizType: quizType)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                }

                // Done button
                Button(action: onDone) {
                    Text("Done")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                        .background(AppColors.tint)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .background(AppColors.background)
        .navigationBarBackButtonHidden()
    }

    private var scoreEmoji: String {
        switch stats.percentage {
        case 90...100: return "🎉"
        case 70...89: return "👍"
        case 50...69: return "📚"
        default: return "💪"
        }
    }

    private var scoreColor: Color {
        switch stats.percentage {
        case 80...100: return AppColors.success
        case 60...79: return AppColors.warning
        default: return AppColors.error
        }
    }
}

private struct StatCell: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
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

private struct ResultRow: View {
    let result: QuizResult
    let quizType: QuizType

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: result.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(result.correct ? AppColors.success : AppColors.error)
                .font(.system(size: 18))

            Text(result.character.character)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(AppColors.text)

            Text("→ \(result.character.romaji)")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            if quizType == .typeA && !result.userAnswer.isEmpty {
                Text(result.userAnswer)
                    .font(AppFonts.caption)
                    .foregroundStyle(result.correct ? AppColors.success : AppColors.error)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(AppColors.cardBorder, lineWidth: 0.5)
        )
    }
}
