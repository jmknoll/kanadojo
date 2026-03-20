import SwiftUI

/// Grading overlay shown after the user submits a word drawing.
/// Always self-graded (no ML model for multi-character words in Phase 7).
struct WordGradingOverlayView: View {
    let kana: String              // correct answer to display
    let userStrokes: [Stroke]
    let hintUsed: Bool
    let drawingCanvasSize: CGFloat
    let onContinue: (Bool) -> Void

    private let displaySize: CGFloat = 140

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Text("How did you do?")
                .font(AppFonts.heading2)
                .foregroundStyle(AppColors.text)

            if hintUsed { hintWarning }

            comparisonRow

            selfGradeButtons
        }
        .padding(AppSpacing.xl)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, AppSpacing.lg)
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
                // Scale font size to fit longer words
                let fontSize: CGFloat = kana.count > 4 ? 40 : kana.count > 2 ? 56 : 80
                Text(kana)
                    .font(.system(size: fontSize, weight: .medium))
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
