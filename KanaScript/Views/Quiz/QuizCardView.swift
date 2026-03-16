import SwiftUI

struct QuizCardView: View {
    let character: KanaCharacter
    let variant: QuizCardVariant

    enum QuizCardVariant {
        case kana    // show the kana character (Type A)
        case romaji  // show the romaji reading (Type B)
    }

    var displayText: String {
        switch variant {
        case .kana: return character.character
        case .romaji: return character.romaji
        }
    }

    var font: Font {
        switch variant {
        case .kana:
            // Combination characters (2 char) get slightly smaller
            return character.character.count > 1 ? AppFonts.kanaMedium : AppFonts.kanaLarge
        case .romaji:
            return AppFonts.heading1
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(displayText)
                .font(font)
                .foregroundStyle(AppColors.text)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            let isHiragana = character.type == .hiragana
            let badgeColor: Color = isHiragana ? AppColors.tint : Color(red: 0.42, green: 0.56, blue: 0.78)
            Text(isHiragana ? "Hiragana" : "Katakana")
                .font(AppFonts.caption)
                .fontWeight(.semibold)
                .foregroundStyle(badgeColor)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(badgeColor.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(badgeColor.opacity(0.3), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
        .padding(.horizontal, AppSpacing.lg)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }
}
