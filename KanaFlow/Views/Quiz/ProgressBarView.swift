import SwiftUI

struct ProgressBarView: View {
    let progress: Double  // 0.0 – 1.0
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.border)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.tint)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(current) / \(total)")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
                Spacer()
            }
        }
    }
}
