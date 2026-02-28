import SwiftUI
import SwiftData

struct StudyView: View {
    @Binding var path: NavigationPath
    @Query private var allProgress: [CharacterProgress]
    @State private var kanaType: KanaType = .hiragana

    private var progressDict: [String: CharacterProgress] {
        Dictionary(uniqueKeysWithValues: allProgress.map { ($0.characterId, $0) })
    }

    private var characters: [KanaCharacter] {
        kanaType == .hiragana ? KanaData.hiragana : KanaData.katakana
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                Picker("Kana Type", selection: $kanaType) {
                    Text("Hiragana").tag(KanaType.hiragana)
                    Text("Katakana").tag(KanaType.katakana)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.lg)

                chartSection(title: "Main · 46", group: .main)
                chartSection(title: "Dakuten · 25", group: .dakuten)
                chartSection(title: "Combination · 36", group: .combination)
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppColors.background)
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func chartSection(title: String, group: KanaGroup) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .font(AppFonts.heading3)
                .foregroundStyle(AppColors.text)
                .padding(.horizontal, AppSpacing.lg)

            KanaChartView(
                group: group,
                characters: characters.filter { $0.group == group },
                progressDict: progressDict,
                onSelect: { char in
                    path.append(AppDestination.characterDetail(character: char))
                }
            )
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}
