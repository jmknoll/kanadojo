import SwiftUI
import SwiftData

struct QuizPlayView: View {
    let config: QuizConfig
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = QuizViewModel()
    @State private var inputText = ""
    @State private var drawingStrokes: [Stroke] = []

    var store: ProgressStore { ProgressStore(context: modelContext) }

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
                    quizType: config.quizType
                ) {
                    // Pop back to home by removing all destinations
                    path = NavigationPath()
                }
            }
        }
        .navigationBarBackButtonHidden(vm.state != .complete)
        .navigationTitle(config.quizType == .typeA ? "Kana → Romaji" : "Romaji → Kana")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if vm.state != .complete {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Quit") {
                        path = NavigationPath()
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
                hintPaths: parsedHintPaths(for: char),
                onSubmit: { strokes in
                    vm.submitDrawing(strokes)
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
            SelfGradeOverlayView(
                character: char,
                userStrokes: vm.submittedStrokes,
                hintUsed: vm.hintUsedThisQuestion,
                onCorrect: {
                    vm.submitSelfGrade(true, store: store)
                },
                onIncorrect: {
                    vm.submitSelfGrade(false, store: store)
                }
            )
        }
    }

    // MARK: - Hint Paths

    private func parsedHintPaths(for char: KanaCharacter) -> [Path] {
        let canvasSize: CGFloat = 260.0
        let kanjivgSize: CGFloat = 109.0

        // Single character: scale to fill the full canvas
        if char.character.count == 1 {
            guard let paths = getStrokeOrder(char.character) else { return [] }
            return paths.map { SVGPathParser.parse($0, scale: canvasSize / kanjivgSize) }
        }

        // Combination kana: lay out two characters side by side
        let chars = Array(char.character)
        guard chars.count == 2 else { return [] }

        // Char 1 (main kana): occupies left ~55% of canvas, vertically centered
        let size1 = canvasSize * 0.55
        let scale1 = size1 / kanjivgSize
        let x1: CGFloat = 0
        let y1 = (canvasSize - size1) / 2

        // Char 2 (small kana): occupies ~40% of canvas, centered in remaining space
        let size2 = canvasSize * 0.40
        let scale2 = size2 / kanjivgSize
        let x2 = size1 + (canvasSize - size1 - size2) / 2
        let y2 = (canvasSize - size2) / 2

        var result: [Path] = []

        func append(character: Character, scale: CGFloat, dx: CGFloat, dy: CGFloat) {
            guard let paths = getStrokeOrder(String(character)) else { return }
            for pathStr in paths {
                let parsed = SVGPathParser.parse(pathStr, scale: scale)
                var t = CGAffineTransform(translationX: dx, y: dy)
                if let cgp = parsed.cgPath.copy(using: &t) {
                    result.append(Path(cgp))
                }
            }
        }

        append(character: chars[0], scale: scale1, dx: x1, dy: y1)
        append(character: chars[1], scale: scale2, dx: x2, dy: y2)

        return result
    }
}
