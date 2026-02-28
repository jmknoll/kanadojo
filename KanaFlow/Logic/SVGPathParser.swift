import SwiftUI

// MARK: - SVG Path Parser
// Parses SVG path d-strings into SwiftUI Path
// Supports: M/m, L/l, C/c, S/s, Q/q, Z/z
// KanjiVG coordinate space: 109×109 → scaled to target canvas size

enum SVGPathParser {
    static func parse(_ d: String, scale: CGFloat = 1.0) -> Path {
        var path = Path()
        let tokens = tokenize(d)
        var idx = 0
        var currentPoint = CGPoint.zero
        var lastControlPoint: CGPoint? = nil
        var lastCommand: Character = "M"

        func nextFloat() -> CGFloat? {
            while idx < tokens.count, tokens[idx] == "," { idx += 1 }
            guard idx < tokens.count, let v = Double(tokens[idx]) else { return nil }
            idx += 1
            return CGFloat(v) * scale
        }

        func nextPoint() -> CGPoint? {
            guard let x = nextFloat(), let y = nextFloat() else { return nil }
            return CGPoint(x: x, y: y)
        }

        while idx < tokens.count {
            let token = tokens[idx]
            if token.count == 1, let ch = token.first, ch.isLetter {
                lastCommand = ch
                idx += 1
            }

            let cmd = lastCommand
            let rel = cmd.isLowercase

            switch cmd.uppercased().first! {
            case "M":
                guard let rawP = nextPoint() else { break }
                let p = rel ? CGPoint(x: currentPoint.x + rawP.x, y: currentPoint.y + rawP.y) : rawP
                path.move(to: p)
                currentPoint = p
                lastControlPoint = nil
                // Subsequent implicit coords after M/m are treated as L/l
                lastCommand = rel ? "l" : "L"

            case "L":
                guard let rawP = nextPoint() else { break }
                let p = rel ? CGPoint(x: currentPoint.x + rawP.x, y: currentPoint.y + rawP.y) : rawP
                path.addLine(to: p)
                currentPoint = p
                lastControlPoint = nil

            case "H":
                guard let rawX = nextFloat() else { break }
                let x = rel ? currentPoint.x + rawX : rawX
                let p = CGPoint(x: x, y: currentPoint.y)
                path.addLine(to: p)
                currentPoint = p
                lastControlPoint = nil

            case "V":
                guard let rawY = nextFloat() else { break }
                let y = rel ? currentPoint.y + rawY : rawY
                let p = CGPoint(x: currentPoint.x, y: y)
                path.addLine(to: p)
                currentPoint = p
                lastControlPoint = nil

            case "C":
                guard let rawC1 = nextPoint(), let rawC2 = nextPoint(), let rawEnd = nextPoint() else { break }
                let c1 = rel ? CGPoint(x: currentPoint.x + rawC1.x, y: currentPoint.y + rawC1.y) : rawC1
                let c2 = rel ? CGPoint(x: currentPoint.x + rawC2.x, y: currentPoint.y + rawC2.y) : rawC2
                let end = rel ? CGPoint(x: currentPoint.x + rawEnd.x, y: currentPoint.y + rawEnd.y) : rawEnd
                path.addCurve(to: end, control1: c1, control2: c2)
                lastControlPoint = c2
                currentPoint = end

            case "S":
                guard let rawC2 = nextPoint(), let rawEnd = nextPoint() else { break }
                let c2 = rel ? CGPoint(x: currentPoint.x + rawC2.x, y: currentPoint.y + rawC2.y) : rawC2
                let end = rel ? CGPoint(x: currentPoint.x + rawEnd.x, y: currentPoint.y + rawEnd.y) : rawEnd
                let c1: CGPoint
                if let lc = lastControlPoint {
                    c1 = CGPoint(x: 2 * currentPoint.x - lc.x, y: 2 * currentPoint.y - lc.y)
                } else {
                    c1 = currentPoint
                }
                path.addCurve(to: end, control1: c1, control2: c2)
                lastControlPoint = c2
                currentPoint = end

            case "Q":
                guard let rawC = nextPoint(), let rawEnd = nextPoint() else { break }
                let c = rel ? CGPoint(x: currentPoint.x + rawC.x, y: currentPoint.y + rawC.y) : rawC
                let end = rel ? CGPoint(x: currentPoint.x + rawEnd.x, y: currentPoint.y + rawEnd.y) : rawEnd
                path.addQuadCurve(to: end, control: c)
                lastControlPoint = c
                currentPoint = end

            case "T":
                guard let rawEnd = nextPoint() else { break }
                let end = rel ? CGPoint(x: currentPoint.x + rawEnd.x, y: currentPoint.y + rawEnd.y) : rawEnd
                let c: CGPoint
                if let lc = lastControlPoint {
                    c = CGPoint(x: 2 * currentPoint.x - lc.x, y: 2 * currentPoint.y - lc.y)
                } else {
                    c = currentPoint
                }
                path.addQuadCurve(to: end, control: c)
                lastControlPoint = c
                currentPoint = end

            case "Z":
                path.closeSubpath()
                lastControlPoint = nil

            default:
                idx += 1
                continue
            }
            // lastCommand is NOT reset here — implicit repetition uses current lastCommand
        }

        return path
    }

    // MARK: - Tokenizer

    private static func tokenize(_ d: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        let commands = Set("MmLlHhVvCcSsQqTtZz")

        for ch in d {
            if commands.contains(ch) {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(ch))
            } else if ch == "," || ch == " " || ch == "\t" || ch == "\n" {
                if !current.isEmpty { tokens.append(current); current = "" }
                if ch == "," { tokens.append(",") }
            } else if ch == "-" {
                if !current.isEmpty { tokens.append(current); current = "" }
                current = "-"
            } else if ch == "." && current.contains(".") {
                // Second decimal: end current number, start new
                tokens.append(current)
                current = "0."
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}
