import SwiftUI

struct RowSelectorView: View {
    @Binding var selectedRows: Set<String>
    let availableRows: [(key: String, kana: String)]

    @State private var isExpanded: Bool = false

    private var headerLabel: String {
        if selectedRows.isEmpty { return "All rows" }
        if selectedRows.count == availableRows.count { return "All rows" }
        return "\(selectedRows.count) row\(selectedRows.count == 1 ? "" : "s") selected"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header row — tappable to expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(headerLabel)
                        .font(AppFonts.body)
                        .foregroundStyle(selectedRows.isEmpty ? AppColors.textSecondary : AppColors.text)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm + 2)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Chip grid — shown when expanded
            if isExpanded {
                FlowLayout(spacing: AppSpacing.sm) {
                    ForEach(availableRows, id: \.key) { row in
                        ChipView(label: row.kana, isSelected: selectedRows.contains(row.key)) {
                            toggleRow(row.key)
                        }
                    }
                }
            }
        }
    }

    private func toggleRow(_ row: String) {
        if selectedRows.contains(row) {
            selectedRows.remove(row)
        } else {
            selectedRows.insert(row)
        }
        // If all rows are explicitly selected, normalise back to "all rows" (empty set)
        if selectedRows.count == availableRows.count {
            selectedRows = []
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
