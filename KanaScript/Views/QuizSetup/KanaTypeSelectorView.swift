import SwiftUI

struct KanaTypeSelectorView: View {
    @Binding var selection: KanaTypeSelection

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(KanaTypeSelection.allCases, id: \.self) { type in
                ChipView(label: type.displayName, isSelected: selection == type) {
                    selection = type
                }
            }
        }
    }
}
