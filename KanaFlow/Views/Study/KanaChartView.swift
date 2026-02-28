import SwiftUI

struct KanaChartView: View {
    let group: KanaGroup
    let characters: [KanaCharacter]
    let progressDict: [String: CharacterProgress]
    let onSelect: (KanaCharacter) -> Void

    private let cellWidth: CGFloat = 60
    private let cellSpacing: CGFloat = 4

    private var columnCount: Int { group == .combination ? 3 : 5 }

    private var rowOrder: [String] {
        switch group {
        case .main:
            return ["a", "ka", "sa", "ta", "na", "ha", "ma", "ya", "ra", "wa", "n"]
        case .dakuten:
            return ["ga", "za", "da", "ba", "pa"]
        case .combination:
            return ["kya", "sha", "cha", "nya", "hya", "mya", "rya", "gya", "ja", "dya", "bya", "pya"]
        }
    }

    // Build each row as an array of optional characters, nil = empty gap cell
    private var rows: [[KanaCharacter?]] {
        let grouped = Dictionary(grouping: characters) { $0.row }
        return rowOrder.compactMap { rowKey -> [KanaCharacter?]? in
            guard let rowChars = grouped[rowKey], !rowChars.isEmpty else { return nil }
            var slots = [KanaCharacter?](repeating: nil, count: columnCount)
            for char in rowChars {
                let col = columnIndex(for: char.romaji)
                guard col < columnCount else { continue }
                slots[col] = char
            }
            return slots
        }
    }

    // Map romaji to grid column
    private func columnIndex(for romaji: String) -> Int {
        if group == .combination {
            if romaji.hasSuffix("a") { return 0 }
            if romaji.hasSuffix("u") { return 1 }
            if romaji.hasSuffix("o") { return 2 }
            return 0
        } else {
            if romaji.hasSuffix("a") { return 0 }
            if romaji.hasSuffix("i") { return 1 }
            if romaji.hasSuffix("u") { return 2 }
            if romaji.hasSuffix("e") { return 3 }
            if romaji.hasSuffix("o") { return 4 }
            return 0  // "n"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: cellSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                let filled = row.compactMap { $0 }
                if filled.count == 1, let single = filled.first {
                    // Single-character row (ん / ン) — don't pad with empty cells
                    ChartCellView(
                        character: single,
                        progress: progressDict[single.id],
                        cellWidth: cellWidth,
                        onTap: { onSelect(single) }
                    )
                } else {
                    HStack(spacing: cellSpacing) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, char in
                            ChartCellView(
                                character: char,
                                progress: char.flatMap { progressDict[$0.id] },
                                cellWidth: cellWidth,
                                onTap: { if let c = char { onSelect(c) } }
                            )
                        }
                    }
                }
            }
        }
    }
}
