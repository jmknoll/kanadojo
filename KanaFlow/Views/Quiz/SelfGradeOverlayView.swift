import SwiftUI

struct SelfGradeOverlayView: View {
    let character: KanaCharacter
    let userStrokes: [Stroke]
    let hintUsed: Bool
    let onCorrect: () -> Void
    let onIncorrect: () -> Void

    private let canvasSize: CGFloat = 140

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Text("How did you do?")
                .font(AppFonts.heading2)
                .foregroundStyle(AppColors.text)

            if hintUsed {
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

            // Side-by-side comparison
            HStack(spacing: AppSpacing.xl) {
                // User drawing
                VStack(spacing: AppSpacing.sm) {
                    Text("Your Answer")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)

                    Canvas { context, size in
                        context.stroke(pathFromStrokes(userStrokes, in: size),
                                        with: .color(AppColors.text),
                                        lineWidth: 3)
                    }
                    .frame(width: canvasSize, height: canvasSize)
                    .background(AppColors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }

                // Correct kana
                VStack(spacing: AppSpacing.sm) {
                    Text("Correct")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)

                    Text(character.character)
                        .font(.system(size: 80, weight: .medium))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .foregroundStyle(AppColors.text)
                        .frame(width: canvasSize, height: canvasSize)
                        .background(AppColors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
            }

            // Grade buttons
            HStack(spacing: AppSpacing.md) {
                Button(action: onIncorrect) {
                    Label("Got it wrong", systemImage: "xmark")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.error)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }

                if !hintUsed {
                    Button(action: onCorrect) {
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
        .padding(AppSpacing.xl)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, AppSpacing.lg)
    }

    private func pathFromStrokes(_ strokes: [Stroke], in size: CGSize) -> Path {
        var path = Path()
        for stroke in strokes {
            guard let first = stroke.first else { continue }
            // Scale from drawing canvas coords to display canvas
            let scale = CGFloat(canvasSize) / 260.0
            path.move(to: CGPoint(x: first.x * scale, y: first.y * scale))
            for point in stroke.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * scale, y: point.y * scale))
            }
        }
        return path
    }
}
