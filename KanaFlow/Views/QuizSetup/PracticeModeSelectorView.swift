import SwiftUI

struct PracticeModeSelectorView: View {
    @Binding var selection: PracticeMode
    let strugglingCount: Int
    let isLoading: Bool

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(PracticeMode.allCases, id: \.self) { mode in
                Button {
                    selection = mode
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(mode.displayName)
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(AppColors.text)
                            Text(mode.description)
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }

                        Spacer()

                        if mode == .struggling {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("\(strugglingCount)")
                                    .font(AppFonts.captionBold)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }

                        Image(systemName: selection == mode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selection == mode ? AppColors.tint : AppColors.border)
                            .font(.system(size: 20))
                    }
                    .padding(AppSpacing.lg)
                    .background(selection == mode ? AppColors.tint.opacity(0.08) : AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(selection == mode ? AppColors.tint : AppColors.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
