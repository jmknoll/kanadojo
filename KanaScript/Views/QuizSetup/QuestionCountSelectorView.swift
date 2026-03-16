import SwiftUI

struct QuestionCountSelectorView: View {
    @Binding var selection: QuestionCount

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(QuestionCount.allCases, id: \.self) { count in
                ChipView(label: count.displayName, isSelected: selection == count) {
                    selection = count
                }
            }
        }
    }
}
