import SwiftUI

struct AnswerInputView: View {
    @Binding var text: String
    let isCorrect: Bool?       // nil = not yet submitted
    let onSubmit: () -> Void
    let onNext: () -> Void     // called when incorrect to dismiss feedback

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            if let correct = isCorrect {
                // Feedback state
                HStack {
                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(correct ? AppColors.success : AppColors.error)
                        .font(.system(size: 24))
                    Text(correct ? "Correct!" : "Incorrect")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(correct ? AppColors.success : AppColors.error)
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background((correct ? AppColors.success : AppColors.error).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                if !correct {
                    Button(action: onNext) {
                        Text("Next")
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.tint)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    }
                }
            } else {
                // Input state
                HStack(spacing: AppSpacing.sm) {
                    TextField("Type romaji...", text: $text)
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(AppColors.text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isFocused)
                        .onSubmit(onSubmit)
                        .padding(AppSpacing.md)
                        .background(AppColors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(AppColors.border, lineWidth: 1)
                        )

                    Button(action: onSubmit) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(text.isEmpty ? AppColors.textMuted : AppColors.tint)
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}
