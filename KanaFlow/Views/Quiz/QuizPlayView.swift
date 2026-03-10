import SwiftUI
import SwiftData

struct QuizPlayView: View {
    let config: QuizConfig
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var vm = QuizViewModel()
    @State private var inputText = ""
    @State private var drawingStrokes: [Stroke] = []

    var store: ProgressStore { ProgressStore(context: modelContext) }

    private var drawingCanvasSize: CGFloat { horizontalSizeClass == .regular ? 380 : 260 }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            switch vm.state {
            case .loading:
                ProgressView("Loading...")
                    .foregroundStyle(AppColors.text)

            case .playing, .feedback:
                if let char = vm.currentCharacter {
                    playingView(char: char)
                }

            case .selfGrading:
                if let char = vm.currentCharacter {
                    selfGradingView(char: char)
                }

            case .complete:
                QuizSummaryView(
                    results: vm.results,
                    quizType: config.quizType,
                    onRepeat: {
                        Task { await vm.load(config: config, store: store) }
                    },
                    onDone: {
                        path.removeLast()
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(vm.state != .complete)
        .navigationTitle(config.quizType == .typeA ? "Kana → Romaji" : "Romaji → Kana")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if vm.state != .complete {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Quit") {
                        path.removeLast()
                    }
                    .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .task {
            await vm.load(config: config, store: store)
        }
    }

    // MARK: - Playing View

    @ViewBuilder
    private func playingView(char: KanaCharacter) -> some View {
        VStack(spacing: AppSpacing.lg) {
            // Progress
            ProgressBarView(
                progress: vm.progress,
                current: vm.currentIndex,
                total: vm.characters.count
            )
            .padding(.horizontal, AppSpacing.lg)

            if config.quizType == .typeA {
                typeAView(char: char)
            } else {
                typeBView(char: char)
            }
        }
        .adaptiveTopPadding()
        .adaptiveContentWidth()
    }

    // MARK: - Type A (Kana → Romaji)

    @ViewBuilder
    private func typeAView(char: KanaCharacter) -> some View {
        VStack(spacing: AppSpacing.xl) {
            QuizCardView(character: char, variant: .kana)
                .padding(.horizontal, AppSpacing.lg)

            AnswerInputView(
                text: $inputText,
                isCorrect: vm.state == .feedback ? vm.lastAnswerCorrect : nil,
                correctAnswer: vm.lastAnswerCorrect == false ? vm.currentCharacter?.romaji : nil,
                onSubmit: {
                    vm.submitAnswer(inputText, store: store)
                    inputText = ""
                },
                onNext: {
                    vm.nextQuestion()
                    inputText = ""
                }
            )
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
        }
        .padding(.top, AppSpacing.md)
    }

    // MARK: - Type B (Romaji → Kana draw)

    @ViewBuilder
    private func typeBView(char: KanaCharacter) -> some View {
        VStack(spacing: AppSpacing.lg) {
            QuizCardView(character: char, variant: .romaji)
                .padding(.horizontal, AppSpacing.lg)

            DrawingCanvasView(
                strokes: $drawingStrokes,
                hintPaths: strokePaths(for: char, in: drawingCanvasSize),
                flashCharacter: char.character,
                canvasSize: drawingCanvasSize,
                onSubmit: { strokes in
                    vm.submitDrawing(strokes, store: store, canvasSize: drawingCanvasSize)
                    drawingStrokes = []
                },
                onHintUsed: {
                    vm.recordHintUsed()
                }
            )
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
        }
        .padding(.top, AppSpacing.md)
    }

    // MARK: - Self Grading

    @ViewBuilder
    private func selfGradingView(char: KanaCharacter) -> some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            GradingOverlayView(
                character: char,
                userStrokes: vm.submittedStrokes,
                mlScore: vm.mlScore,
                hintUsed: vm.hintUsedThisQuestion,
                drawingCanvasSize: drawingCanvasSize,
                onContinue: { wasCorrect in
                    vm.submitGrade(wasCorrect, store: store)
                }
            )
        }
    }

}
