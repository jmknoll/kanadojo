import SwiftUI

struct DrawingCanvasView: View {
    @Binding var strokes: [Stroke]
    var hintPaths: [Path]
    var onSubmit: ([Stroke]) -> Void
    var onHintUsed: () -> Void

    @State private var currentStroke: Stroke = []
    @State private var revealedHintCount: Int = 0

    private let canvasSize: CGFloat = 260
    private let strokeWidth: CGFloat = 4

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Canvas
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )

                // Hint strokes (red, 40% opacity)
                Canvas { context, _ in
                    for i in 0..<revealedHintCount where i < hintPaths.count {
                        context.opacity = 0.4
                        context.stroke(hintPaths[i],
                                        with: .color(.red),
                                        lineWidth: strokeWidth)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))

                // User strokes
                Canvas { context, _ in
                    for stroke in strokes {
                        context.stroke(pathFromStroke(stroke),
                                        with: .color(AppColors.text),
                                        lineWidth: strokeWidth)
                    }
                    if !currentStroke.isEmpty {
                        context.stroke(pathFromStroke(currentStroke),
                                        with: .color(AppColors.text),
                                        lineWidth: strokeWidth)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .frame(width: canvasSize, height: canvasSize)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentStroke.append(value.location)
                    }
                    .onEnded { value in
                        currentStroke.append(value.location)
                        if !currentStroke.isEmpty {
                            strokes.append(currentStroke)
                        }
                        currentStroke = []
                    }
            )

            // Toolbar
            HStack(spacing: AppSpacing.lg) {
                // Undo
                Button {
                    if !strokes.isEmpty { strokes.removeLast() }
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(AppFonts.caption)
                        .foregroundStyle(strokes.isEmpty ? AppColors.textMuted : AppColors.textSecondary)
                }
                .disabled(strokes.isEmpty)

                // Clear
                Button {
                    strokes = []
                } label: {
                    Label("Clear", systemImage: "xmark")
                        .font(AppFonts.caption)
                        .foregroundStyle(strokes.isEmpty ? AppColors.textMuted : AppColors.textSecondary)
                }
                .disabled(strokes.isEmpty)

                Spacer()

                // Hint
                if !hintPaths.isEmpty {
                    Button {
                        if revealedHintCount < hintPaths.count {
                            revealedHintCount += 1
                            onHintUsed()
                        }
                    } label: {
                        Label(
                            revealedHintCount >= hintPaths.count ? "All hints" : "Hint (\(revealedHintCount)/\(hintPaths.count))",
                            systemImage: "lightbulb"
                        )
                        .font(AppFonts.caption)
                        .foregroundStyle(revealedHintCount >= hintPaths.count ? AppColors.textMuted : AppColors.warning)
                    }
                    .disabled(revealedHintCount >= hintPaths.count)
                }

                // Submit
                Button {
                    onSubmit(strokes)
                    revealedHintCount = 0
                } label: {
                    Text("Submit")
                        .font(AppFonts.label)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(strokes.isEmpty ? AppColors.textMuted : AppColors.tint)
                        .clipShape(Capsule())
                }
                .disabled(strokes.isEmpty)
            }
            .padding(.horizontal, AppSpacing.xs)
        }
    }

    private func pathFromStroke(_ stroke: Stroke) -> Path {
        var path = Path()
        guard let first = stroke.first else { return path }
        path.move(to: first)
        for point in stroke.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}
