import SwiftUI
import SwiftData

struct WordSetupView: View {
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var scriptType: WordScriptType = .hiragana
    @State private var selectedCategories: [WordCategory] = []
    @State private var sessionLength: WordSessionLength = .twenty
    @State private var showOnboarding: Bool = false
    @AppStorage("wordWritingOnboardingSeen") private var onboardingSeen: Bool = false

    private var filteredWords: [WordEntry] {
        WordData.getWords(scriptType: scriptType, categories: selectedCategories)
    }

    private var filteredCount: Int { filteredWords.count }

    private var canStart: Bool { filteredCount > 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 36 : AppSpacing.xxl) {

                // Script Type
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Script")
                    Picker("Script", selection: $scriptType) {
                        ForEach(WordScriptType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Category filter
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Categories")
                    categorySelector
                }

                // Session length
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Session Length")
                    Picker("Session Length", selection: $sessionLength) {
                        ForEach(WordSessionLength.allCases, id: \.self) { len in
                            Text(len.displayName).tag(len)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Summary + Start
                VStack(spacing: AppSpacing.md) {
                    Text(summaryText)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Button {
                        startSession()
                    } label: {
                        Text("Start")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                            .background(canStart ? AppColors.tint : AppColors.textMuted)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    }
                    .disabled(!canStart)
                }
            }
            .padding(AppSpacing.lg)
            .adaptiveTopPadding()
            .adaptiveContentWidth()
        }
        .background(AppColors.background)
        .navigationTitle("Words")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !onboardingSeen { showOnboarding = true }
        }
        .sheet(isPresented: $showOnboarding) {
            onboardingSheet
        }
        .onChange(of: scriptType) { selectedCategories = [] }
    }

    // MARK: - Category Selector

    private var categorySelector: some View {
        let availableCategories = WordCategory.allCases.filter { cat in
            WordData.getWords(scriptType: scriptType, categories: [cat]).count > 0
        }

        return FlowLayout(spacing: AppSpacing.sm) {
            // "All" chip
            ChipView(
                label: "All",
                isSelected: selectedCategories.isEmpty
            ) {
                selectedCategories = []
            }

            ForEach(availableCategories, id: \.self) { cat in
                ChipView(
                    label: cat.rawValue,
                    isSelected: selectedCategories.contains(cat)
                ) {
                    if selectedCategories.contains(cat) {
                        selectedCategories.removeAll { $0 == cat }
                    } else {
                        selectedCategories.append(cat)
                    }
                }
            }
        }
    }

    // MARK: - Summary Text

    private var summaryText: String {
        let catLabel = selectedCategories.isEmpty ? "all categories" : "\(selectedCategories.count) categor\(selectedCategories.count == 1 ? "y" : "ies")"
        let actualCount = min(sessionLength.rawValue, filteredCount)
        return "\(actualCount) of \(filteredCount) \(scriptType.displayName.lowercased()) words from \(catLabel)"
    }

    // MARK: - Start

    private func startSession() {
        let store = WordProgressStore(context: modelContext)
        let pool = store.buildSessionPool(from: filteredWords, count: sessionLength.rawValue)
        let config = WordQuizConfig(
            scriptType: scriptType,
            selectedCategories: selectedCategories,
            sessionLength: sessionLength,
            wordPool: pool
        )
        path.append(AppDestination.wordQuiz(config: config))
    }

    // MARK: - Onboarding Sheet

    private var onboardingSheet: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.tint)

            VStack(spacing: AppSpacing.md) {
                Text("Word Writing Mode")
                    .font(AppFonts.heading2)
                    .foregroundStyle(AppColors.text)

                Text("Write complete words in kana from memory. After drawing, compare your writing to the correct spelling and grade yourself.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text("Recommended once you're comfortable writing individual kana characters.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }

            Button {
                onboardingSeen = true
                showOnboarding = false
            } label: {
                Text("Got it")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(AppColors.tint)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
        }
        .padding(AppSpacing.xl)
        .presentationDetents([.medium])
    }
}

// MARK: - FlowLayout

/// Simple wrapping layout for chips that don't fit in a single HStack.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width + (rowWidth > 0 ? spacing : 0) > maxWidth {
                height += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += size.width + (rowWidth > 0 ? spacing : 0)
                rowHeight = max(rowHeight, size.height)
            }
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
