import SwiftUI

struct ChartCellView: View {
    let character: KanaCharacter?
    let progress: CharacterProgress?
    let onTap: () -> Void

    private var isCombination: Bool {
        (character?.character.count ?? 1) > 1
    }

    private var cellBackground: Color {
        guard let p = progress, p.totalCount >= 3 else { return AppColors.cardBackground }
        return p.accuracy >= 0.7
            ? AppColors.success.opacity(0.1)
            : AppColors.error.opacity(0.1)
    }

    var body: some View {
        if let char = character {
            Button(action: onTap) {
                VStack(spacing: 2) {
                    Text(char.character)
                        .font(.system(size: isCombination ? 15 : 22, weight: .medium))
                        .foregroundStyle(AppColors.text)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text(char.romaji)
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textSecondary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: 68)
                .background(cellBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(AppColors.cardBorder, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        } else {
            // Empty gap cell — preserves grid alignment
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 68)
        }
    }
}
