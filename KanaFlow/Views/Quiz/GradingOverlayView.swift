import SwiftUI

/// Grading overlay shown after the user submits a Type B drawing.
///
/// Two possible states:
///   1. Embedding model available — shows quality score bar and pass/fail.
///   2. No model (qualityResult == nil) — self-grade buttons shown as fallback.
struct GradingOverlayView: View {
    let character: KanaCharacter
    let userStrokes: [Stroke]
    let qualityResult: QualityResult?
    let hintUsed: Bool
    let drawingCanvasSize: CGFloat
    let onContinue: (Bool) -> Void

    private let displaySize: CGFloat = 140

    @State private var animatedScore: Float = 0

    /// The final pass/fail, accounting for hint usage and quality score.
    private var effectivePassed: Bool {
        guard !hintUsed else { return false }
        return qualityResult?.passed ?? false
    }

    private var titleText: String {
        guard let q = qualityResult else { return "How did you do?" }
        return q.passed ? "Nice work!" : "Keep practicing"
    }

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Text(titleText)
                .font(AppFonts.heading2)
                .foregroundStyle(AppColors.text)

            if hintUsed { hintWarning }

            comparisonRow

            if let q = qualityResult {
                // Embedding quality score available
                qualitySection(q)
                continueButton(passed: effectivePassed)
            } else {
                // Model unavailable — fall back to self-grade
                selfGradeButtons
            }
        }
        .padding(AppSpacing.xl)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, AppSpacing.lg)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                animatedScore = qualityResult?.score ?? 0
            }
        }
    }

    // MARK: - Sub-views

    private var hintWarning: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.warning)
            Text("Hint used — marked incorrect")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.warning)
        }
        .padding(AppSpacing.md)
        .background(AppColors.warning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var comparisonRow: some View {
        HStack(spacing: AppSpacing.xl) {
            VStack(spacing: AppSpacing.sm) {
                Text("Your Answer")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
                Canvas { context, size in
                    context.stroke(
                        pathFromStrokes(userStrokes, targetSize: size.width),
                        with: .color(AppColors.text),
                        lineWidth: 3
                    )
                }
                .frame(width: displaySize, height: displaySize)
                .background(AppColors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.border, lineWidth: 1))
            }

            VStack(spacing: AppSpacing.sm) {
                Text("Correct")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
                Text(character.character)
                    .font(.system(size: 80, weight: .medium))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .foregroundStyle(AppColors.text)
                    .frame(width: displaySize, height: displaySize)
                    .background(AppColors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.border, lineWidth: 1))
            }
        }
    }

    /// Displays the embedding quality score.
    @ViewBuilder
    private func qualitySection(_ quality: QualityResult) -> some View {
        VStack(spacing: AppSpacing.md) {
            // Badge — shows actual quality regardless of hint
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: quality.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(quality.passed ? AppColors.success : AppColors.error)
                    .font(.system(size: 20))
                Text(quality.passed ? "Great form!" : "Needs work")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(quality.passed ? AppColors.success : AppColors.error)
            }

            // Animated quality bar
            HStack(spacing: AppSpacing.sm) {
                Text("Quality")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 56, alignment: .leading)

                GeometryReader { geo in
                    let fillWidth = geo.size.width * CGFloat(animatedScore)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(AppColors.border)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(quality.passed ? AppColors.success : AppColors.error)
                            .frame(width: fillWidth)
                    }
                }
                .frame(height: 8)

                Text("\(Int(animatedScore * 100))%")
                    .font(AppFonts.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 36, alignment: .trailing)
                    .contentTransition(.numericText())
            }
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            // Stroke count hint
            if !quality.strokeCountCorrect {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(AppColors.textMuted)
                        .font(.system(size: 13))
                    Text("\(character.character) has \(quality.referenceStrokeCount) stroke\(quality.referenceStrokeCount == 1 ? "" : "s") — you drew \(quality.userStrokeCount)")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.sm)
                .background(AppColors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }

    private func continueButton(passed: Bool) -> some View {
        Button { onContinue(passed) } label: {
            Text("Continue")
                .font(AppFonts.bodyMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(effectivePassed ? AppColors.success : AppColors.error)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }

    private var selfGradeButtons: some View {
        HStack(spacing: AppSpacing.md) {
            Button { onContinue(false) } label: {
                Label("Got it wrong", systemImage: "xmark")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.error)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            if !hintUsed {
                Button { onContinue(true) } label: {
                    Label("Got it right", systemImage: "checkmark")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.success)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
            }
        }
    }

    // MARK: - Helpers

    private func pathFromStrokes(_ strokes: [Stroke], targetSize: CGFloat) -> Path {
        var path = Path()
        let scale = targetSize / drawingCanvasSize
        for stroke in strokes {
            guard let first = stroke.first else { continue }
            path.move(to: CGPoint(x: first.x * scale, y: first.y * scale))
            for pt in stroke.dropFirst() {
                path.addLine(to: CGPoint(x: pt.x * scale, y: pt.y * scale))
            }
        }
        return path
    }
}
