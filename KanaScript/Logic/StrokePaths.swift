import SwiftUI

// Converts KanjiVG stroke data into scaled SwiftUI Paths.
// Shared by QuizPlayView (hint rendering) and CharacterDetailView (stroke order display).
func strokePaths(for character: KanaCharacter, in canvasSize: CGFloat) -> [Path] {
    let kanjivgSize: CGFloat = 109.0

    // Single character: scale to fill the full canvas
    if character.character.count == 1 {
        guard let paths = getStrokeOrder(character.character) else { return [] }
        return paths.map { SVGPathParser.parse($0, scale: canvasSize / kanjivgSize) }
    }

    // Combination kana: lay out two characters side by side
    let chars = Array(character.character)
    guard chars.count == 2 else { return [] }

    // Char 1 (main kana): occupies left ~55% of canvas, vertically centered
    let size1 = canvasSize * 0.55
    let scale1 = size1 / kanjivgSize
    let x1: CGFloat = 0
    let y1 = (canvasSize - size1) / 2

    // Char 2 (small kana): occupies ~40% of canvas, centered in remaining space
    let size2 = canvasSize * 0.40
    let scale2 = size2 / kanjivgSize
    let x2 = size1 + (canvasSize - size1 - size2) / 2
    let y2 = (canvasSize - size2) / 2

    var result: [Path] = []

    func append(char: Character, scale: CGFloat, dx: CGFloat, dy: CGFloat) {
        guard let paths = getStrokeOrder(String(char)) else { return }
        for pathStr in paths {
            let parsed = SVGPathParser.parse(pathStr, scale: scale)
            var t = CGAffineTransform(translationX: dx, y: dy)
            if let cgp = parsed.cgPath.copy(using: &t) {
                result.append(Path(cgp))
            }
        }
    }

    append(char: chars[0], scale: scale1, dx: x1, dy: y1)
    append(char: chars[1], scale: scale2, dx: x2, dy: y2)

    return result
}
