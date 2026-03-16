import SwiftUI

struct SectionHeaderView: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFonts.heading3)
                .foregroundStyle(AppColors.text)
            if let subtitle {
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
