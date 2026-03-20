import SwiftUI
import SwiftData

struct WordQuizPlayView: View {
    let config: WordQuizConfig
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var vm = WordQuizViewModel()
    @State private var drawingStrokes: [Stroke] = []

    private var canvasSize: CGFloat { horizontalSizeClass == .regular ? 380 : 260 }
    private var wordStore: WordProgressStore { WordProgressStore(context: modelContext) }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            switch vm.state {
            case .prompt:
                if let word = vm.currentWord {
                    WordPromptView(
                        word: word,
                        kana: vm.currentKana,
                        progress: vm.progress,
                        current: vm.currentIndex,
                        total: vm.words.count,
                        onHintUsed: { vm.recordHintUsed() },
                        onStartDrawing: { vm.startDrawing() }
                    )
                }

            case .drawing:
                drawingView

            case .grading:
                gradingView

            case .complete:
                WordQuizSummaryView(
                    results: vm.results,
                    onRepeat: {
                        drawingStrokes = []
                        vm.load(config: config)
                    },
                    onDone: {
                        path.removeLast()
                    }
                )
            }
        }
        .navigationTitle("Word Writing")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(vm.state != .complete)
        .toolbar {
            if vm.state != .complete {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Quit") { path.removeLast() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .onAppear { vm.load(config: config) }
    }

    // MARK: - Drawing View

    @ViewBuilder
    private var drawingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressBarView(
                progress: vm.progress,
                current: vm.currentIndex,
                total: vm.words.count
            )
            .padding(.horizontal, AppSpacing.lg)

            // Romaji reminder above canvas
            Text(vm.currentWord?.romaji ?? "")
                .font(AppFonts.heading2)
                .foregroundStyle(AppColors.textMuted)

            DrawingCanvasView(
                strokes: $drawingStrokes,
                hintPaths: [],
                flashCharacter: vm.currentKana,
                canvasSize: canvasSize,
                onSubmit: { strokes in
                    vm.submitDrawing(strokes)
                },
                onHintUsed: {
                    vm.recordHintUsed()
                }
            )
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
        }
        .adaptiveTopPadding()
        .adaptiveContentWidth()
    }

    // MARK: - Grading Overlay

    @ViewBuilder
    private var gradingView: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            WordGradingOverlayView(
                kana: vm.currentKana,
                userStrokes: vm.submittedStrokes,
                hintUsed: vm.hintUsed,
                drawingCanvasSize: canvasSize,
                onContinue: { wasCorrect in
                    drawingStrokes = []
                    vm.submitGrade(wasCorrect, store: wordStore)
                }
            )
        }
    }
}
