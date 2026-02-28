import SwiftUI

struct GroupChipSelectorView: View {
    @Binding var selection: GroupSelection

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(GroupSelection.allCases, id: \.self) { group in
                ChipView(label: group.displayName, isSelected: selection == group) {
                    selection = group
                }
            }
        }
    }
}
