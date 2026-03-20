import SwiftUI

struct WordPromptView: View {
    let word: WordEntry
    let kana: String          // pre-resolved for the session's script type
    let progress: Double
    let current: Int
    let total: Int
    let onHintUsed: () -> Void
    let onStartDrawing: () -> Void

    @State private var kanaRevealed: Bool = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Progress bar
            ProgressBarView(progress: progress, current: current, total: total)
                .padding(.horizontal, AppSpacing.lg)

            Spacer()

            // Prompt card
            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.sm) {
                    Text(word.english)
                        .font(AppFonts.heading3)
                        .foregroundStyle(AppColors.textMuted)
                        .multilineTextAlignment(.center)

                    Text(word.romaji)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(AppColors.text)
                        .multilineTextAlignment(.center)
                }

                // Kana hint reveal
                if kanaRevealed {
                    Text(kana)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.lg)
                        .background(AppColors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            // Action buttons
            VStack(spacing: AppSpacing.md) {
                if !kanaRevealed {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            kanaRevealed = true
                        }
                        onHintUsed()
                    } label: {
                        Label("Show kana (counts as incorrect)", systemImage: "eye")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.warning)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onStartDrawing) {
                    Text("Start Writing")
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
        .background(AppColors.background)
        .adaptiveTopPadding()
        .adaptiveContentWidth()
        .onChange(of: word.id) { kanaRevealed = false }
    }
}
