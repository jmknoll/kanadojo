import SwiftUI

struct AnswerInputView: View {
    @Binding var text: String
    let isCorrect: Bool?        // nil = not yet submitted
    let correctAnswer: String?  // shown when isCorrect == false
    let onSubmit: () -> Void
    let onNext: () -> Void      // called when incorrect to advance

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Feedback banner — shown after submission
            if let correct = isCorrect {
                HStack {
                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(correct ? AppColors.success : AppColors.error)
                        .font(.system(size: 24))
                    Text(correct ? "Correct!" : "Incorrect")
                        .font(AppFonts.bodyMedium)
                        .foregroundStyle(correct ? AppColors.success : AppColors.error)
                    Spacer()
                    if !correct, let answer = correctAnswer {
                        Text(answer)
                            .font(AppFonts.bodyMedium)
                            .foregroundStyle(AppColors.text)
                    }
                }
                .padding(AppSpacing.md)
                .background((correct ? AppColors.success : AppColors.error).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }

            // Input row — always in hierarchy so the keyboard stays up
            HStack(spacing: AppSpacing.sm) {
                TextField("Type romaji...", text: $text)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .disabled(isCorrect != nil)
                    .onSubmit {
                        if isCorrect == nil {
                            onSubmit()
                        } else if isCorrect == false {
                            onNext()
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(
                                isCorrect == nil ? AppColors.border : AppColors.border.opacity(0.3),
                                lineWidth: 1
                            )
                    )

                // Action button changes role: submit → next → hidden (auto-advancing correct)
                if isCorrect == nil {
                    Button(action: onSubmit) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(text.isEmpty ? AppColors.textMuted : AppColors.tint)
                    }
                    .disabled(text.isEmpty)
                } else if isCorrect == false {
                    Button(action: onNext) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(AppColors.tint)
                    }
                } else {
                    // Correct — auto-advancing, show disabled arrow as placeholder
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
        }
        .onAppear {
            isFocused = true
        }
        .onChange(of: isCorrect) {
            // Re-focus when a new question starts (isCorrect resets to nil)
            if isCorrect == nil {
                isFocused = true
            }
        }
    }
}
