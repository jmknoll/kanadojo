import SwiftUI

struct MasteryBadge: View {
    let level: MasteryLevel

    var body: some View {
        if level != .new {
            Text(level.displayName)
                .font(AppFonts.small)
                .foregroundStyle(level.color)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 2)
                .background(level.color.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}
