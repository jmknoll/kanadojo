import SwiftUI

/// Grading overlay shown after the user submits a Type B drawing.
///
/// - When `scores` is non-nil: shows the automatically computed score breakdown
///   and a "Continue" button. The user has no choice — the grade is final.
/// - When `scores` is nil: no reference stroke data was available for this character;
///   falls back to the original self-grading buttons.
struct GradingOverlayView: View {
    let character: KanaCharacter
    let userStrokes: [Stroke]
    let scores: StrokeScores?
    let hintUsed: Bool
    let drawingCanvasSize: CGFloat
    let onContinue: (Bool) -> Void  // passes wasCorrect

    private let displaySize: CGFloat = 140

    // The effective result accounting for hint penalty
    private var effectivePassed: Bool {
        guard let s = scores else { return false }
        return hintUsed ? false : s.passed
    }

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            titleRow
            if hintUsed { hintWarning }
            comparisonRow
            if let s = scores {
                scoreSection(s)
                continueButton(s)
            } else {
                selfGradeButtons
            }
        }
        .padding(AppSpacing.xl)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Sub-views

    private var titleRow: some View {
        Group {
            if scores != nil {
                Text(effectivePassed ? "Nice work!" : "Keep practicing")
                    .font(AppFonts.heading2)
                    .foregroundStyle(AppColors.text)
            } else {
                Text("How did you do?")
                    .font(AppFonts.heading2)
                    .foregroundStyle(AppColors.text)
            }
        }
    }

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
            // User's drawing
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

            // Correct character
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

    @ViewBuilder
    private func scoreSection(_ s: StrokeScores) -> some View {
        VStack(spacing: AppSpacing.md) {
            // Overall pass/fail badge
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: effectivePassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(effectivePassed ? AppColors.success : AppColors.error)
                    .font(.system(size: 20))
                Text("Overall: \(Int(s.overall * 100))%")
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(effectivePassed ? AppColors.success : AppColors.error)
            }

            // Score bars
            VStack(spacing: AppSpacing.sm) {
                scoreBar(label: "Shape",        value: s.shape)
                scoreBar(label: "Proportion",   value: s.proportion)
                scoreBar(label: "Stroke Order", value: s.strokeOrder)
                scoreBar(label: "Consistency",  value: s.consistency)
            }
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    private func scoreBar(label: String, value: Double) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 88, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(AppColors.border)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(value))
                        .frame(width: geo.size.width * CGFloat(value))
                }
            }
            .frame(height: 6)

            Text("\(Int(value * 100))%")
                .font(AppFonts.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private func barColor(_ v: Double) -> Color {
        v >= 0.7 ? AppColors.success : v >= 0.5 ? AppColors.warning : AppColors.error
    }

    private func continueButton(_ s: StrokeScores) -> some View {
        Button {
            onContinue(s.passed)
        } label: {
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
