import SwiftUI

struct HomeTileView: View {
    let title: String
    let subtitle: String
    let icon: String
    let isEnabled: Bool
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(isEnabled ? AppColors.tint : AppColors.textMuted)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(title)
                            .font(AppFonts.heading3)
                            .foregroundStyle(isEnabled ? AppColors.text : AppColors.textMuted)

                        if let badge {
                            Text(badge)
                                .font(AppFonts.small)
                                .foregroundStyle(.white)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, 2)
                                .background(AppColors.textMuted)
                                .clipShape(Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                Spacer()

                if isEnabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}
