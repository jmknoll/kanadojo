import SwiftUI

struct QuizTypeSelectorView: View {
    @Binding var selection: QuizType

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(QuizType.allCases, id: \.self) { type in
                Button {
                    selection = type
                } label: {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack {
                            Text(type.displayName)
                                .font(AppFonts.bodyMedium)
                                .foregroundStyle(AppColors.text)
                            Spacer()
                            Image(systemName: selection == type ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection == type ? AppColors.tint : AppColors.border)
                        }
                        Text(type.description)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(selection == type ? AppColors.tint.opacity(0.08) : AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(selection == type ? AppColors.tint : AppColors.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
