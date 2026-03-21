import SwiftUI

struct WordQuizSummaryView: View {
    let results: [(word: WordEntry, kana: String, correct: Bool)]
    let onRepeat: () -> Void
    let onDone: () -> Void

    private var correct: Int { results.filter(\.correct).count }
    private var total: Int { results.count }
    private var percentage: Int { total > 0 ? Int(Double(correct) / Double(total) * 100) : 0 }

    private var scoreColor: Color {
        switch percentage {
        case 80...100: return AppColors.success
        case 60...79:  return AppColors.warning
        default:       return AppColors.error
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Score header
                VStack(spacing: AppSpacing.md) {
                    Text("\(percentage)%")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(scoreColor)

                    Text("\(correct) of \(total) correct")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.top, AppSpacing.xxl)

                // Stats row
                HStack(spacing: 0) {
                    StatCell(label: "Correct",   value: "\(correct)",        color: AppColors.success)
                    Divider()
                    StatCell(label: "Incorrect", value: "\(total - correct)", color: AppColors.error)
                    Divider()
                    StatCell(label: "Total",     value: "\(total)",           color: AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(AppColors.cardBorder, lineWidth: 1))
                .padding(.horizontal, AppSpacing.lg)

                // Result list
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Results")
                        .font(AppFonts.heading3)
                        .foregroundStyle(AppColors.text)
                        .padding(.horizontal, AppSpacing.lg)

                    ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                        WordResultRow(result: result)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                }

                // Actions
                VStack(spacing: AppSpacing.md) {
                    Button(action: onRepeat) {
                        Text("Repeat Session")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.tint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                            .background(AppColors.tint.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    }

                    Button(action: onDone) {
                        Text("Done")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                            .background(AppColors.tint)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .adaptiveTopPadding()
            .adaptiveContentWidth()
        }
        .background(AppColors.background)
        .navigationTitle("Session Complete")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

// MARK: - StatCell (local — mirrors QuizSummaryView.StatCell)

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

// MARK: - WordResultRow

private struct WordResultRow: View {
    let result: (word: WordEntry, kana: String, correct: Bool)

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: result.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(result.correct ? AppColors.success : AppColors.error)
                .font(.system(size: 18))

            Text(result.kana)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(AppColors.text)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.word.romaji)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                Text(result.word.english)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.cardBorder, lineWidth: 0.5))
    }
}
