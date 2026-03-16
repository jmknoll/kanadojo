import SwiftUI

struct ChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.label)
                .foregroundStyle(isSelected ? .white : AppColors.text)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColors.tint : AppColors.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppColors.tint : AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
