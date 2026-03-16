import SwiftUI

struct KanaChartView: View {
    let group: KanaGroup
    let characters: [KanaCharacter]
    let progressDict: [String: CharacterProgress]
    let onSelect: (KanaCharacter) -> Void

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

    // Flatten rows into indexed items for LazyVGrid
    private var flatItems: [(id: String, char: KanaCharacter?)] {
        rows.enumerated().flatMap { rowIdx, row in
            row.enumerated().map { colIdx, char in
                (id: "\(rowIdx)-\(colIdx)", char: char)
            }
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
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: cellSpacing),
            count: columnCount
        )

        LazyVGrid(columns: columns, spacing: cellSpacing) {
            ForEach(flatItems, id: \.id) { item in
                ChartCellView(
                    character: item.char,
                    progress: item.char.flatMap { progressDict[$0.id] },
                    onTap: { if let c = item.char { onSelect(c) } }
                )
            }
        }
    }
}
