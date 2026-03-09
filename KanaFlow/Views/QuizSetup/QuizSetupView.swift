import SwiftUI
import SwiftData

struct QuizSetupView: View {
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var vm = QuizSetupViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 36 : AppSpacing.xxl) {

                // Kana Type
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Kana Type")
                    KanaTypeSelectorView(selection: $vm.kanaType)
                }

                // Group
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Character Group")
                    GroupChipSelectorView(selection: $vm.group)
                }

                // Row filter (optional)
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Rows")
                    RowSelectorView(selectedRows: $vm.selectedRows, availableRows: vm.availableRows)
                }

                // Quiz Type
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Quiz Type")
                    QuizTypeSelectorView(selection: $vm.quizType)
                }

                // Practice Mode
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Practice Mode")
                    PracticeModeSelectorView(selection: $vm.practiceMode,
                                             strugglingCount: vm.strugglingCount,
                                             isLoading: vm.isLoadingStruggling)
                }

                // Question Count
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SectionHeaderView(title: "Questions")
                    QuestionCountSelectorView(selection: $vm.questionCount)
                }

                // Summary + Start
                VStack(spacing: AppSpacing.md) {
                    Text(vm.summaryText)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Button {
                        path.append(AppDestination.quizPlay(config: vm.config))
                    } label: {
                        Text("Start Quiz")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                            .background(vm.canStart ? AppColors.tint : AppColors.textMuted)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    }
                    .disabled(!vm.canStart)
                }
            }
            .padding(AppSpacing.lg)
            .adaptiveTopPadding()
            .adaptiveContentWidth()
        }
        .background(AppColors.background)
        .navigationTitle("Quiz Setup")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let store = ProgressStore(context: modelContext)
            await vm.refreshStrugglingCount(store: store)
        }
        .onChange(of: vm.kanaType) {
            vm.selectedRows = []
            Task {
                let store = ProgressStore(context: modelContext)
                await vm.refreshStrugglingCount(store: store)
            }
        }
        .onChange(of: vm.group) {
            vm.selectedRows = []
            Task {
                let store = ProgressStore(context: modelContext)
                await vm.refreshStrugglingCount(store: store)
            }
        }
        .onChange(of: vm.selectedRows) {
            Task {
                let store = ProgressStore(context: modelContext)
                await vm.refreshStrugglingCount(store: store)
            }
        }
    }
}
