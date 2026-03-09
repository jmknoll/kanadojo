import Foundation
import CoreGraphics

// MARK: - StrokeScores

struct StrokeScores {
    let shape: Double          // 0–1
    let proportion: Double     // 0–1
    let strokeOrder: Double    // 0–1
    let consistency: Double    // 0–1
    let overall: Double        // weighted grade

    var passed: Bool { overall >= 0.65 }
}

// MARK: - Public API

/// Grade a user's drawn strokes against the KanjiVG reference for the given character.
/// Returns nil if no reference data is available (caller should fall back to self-grading).
/// - Parameters:
///   - userStrokes: Raw stroke coordinates in [0, canvasSize]² space.
///   - character: The character being graded.
///   - priorShapeEMA: The EMA of shape scores stored on CharacterProgress (0 on first attempt).
///   - canvasSize: The pixel dimensions of the drawing canvas used to normalise user strokes.
func gradeDrawing(
    userStrokes: [Stroke],
    character: KanaCharacter,
    priorShapeEMA: Double,
    canvasSize: CGFloat
) -> StrokeScores? {
    guard !userStrokes.isEmpty,
          let refStrokes = referenceStrokes(for: character),
          !refStrokes.isEmpty
    else { return nil }

    let isCombination = character.character.count > 1

    // Normalise user strokes from canvas space to [0,1]²
    let normUser = userStrokes.map { stroke in
        stroke.map { CGPoint(x: $0.x / canvasSize, y: $0.y / canvasSize) }
    }

    // Match user strokes to reference strokes (greedy nearest-DTW)
    let (matches, orderedRefIndices) = matchStrokes(user: normUser, reference: refStrokes)

    // Compute sub-scores
    // Shape: normalise both drawings to character space (bounding-box centred,
    // largest dimension = 1), rasterise into an 8×8 grid, and compare with
    // cosine similarity. This captures loops, crossings, and relative stroke
    // positions — features that per-stroke direction comparison misses.
    let shapeSc      = gridShapeScore(userStrokes: normUser, refStrokes: refStrokes)
    let proportionSc = proportionScore(matches: matches, userStrokes: normUser, refStrokes: refStrokes)
    let orderSc      = strokeOrderScore(
        orderedRefIndices: orderedRefIndices,
        userCount: userStrokes.count,
        refCount: refStrokes.count
    )

    // Consistency: how close is this attempt to the running EMA?
    // First attempt: no prior data, so no consistency score.
    let consistencySc = priorShapeEMA == 0
        ? 0.0
        : max(0, 1.0 - abs(shapeSc - priorShapeEMA))

    let overall = 0.75 * shapeSc + 0.15 * proportionSc + 0.10 * orderSc

    return StrokeScores(
        shape: shapeSc,
        proportion: proportionSc,
        strokeOrder: orderSc,
        consistency: consistencySc,
        overall: max(0, min(1, overall))
    )
}

// MARK: - Reference Stroke Cache

// Lazily populated per-character cache of normalised reference strokes.
// All coordinates are in [0,1]² space.
private var referenceStrokesCache: [String: [[CGPoint]]] = [:]

func referenceStrokes(for character: KanaCharacter) -> [[CGPoint]]? {
    let key = character.character
    if let cached = referenceStrokesCache[key] { return cached }

    let result = buildReferenceStrokes(for: character)
    if let r = result { referenceStrokesCache[key] = r }
    return result
}

private func buildReferenceStrokes(for character: KanaCharacter) -> [[CGPoint]]? {
    let kanjivgSize = 109.0

    if character.character.count == 1 {
        guard let paths = getStrokeOrder(character.character) else { return nil }
        let strokes = paths.map { sampleSVGPath($0, scale: 1.0 / kanjivgSize) }
        return strokes.isEmpty ? nil : strokes

    } else {
        // Combination kana: tile two characters side by side using the same
        // geometry as StrokePaths.strokePaths(for:in:).
        let chars = Array(character.character)
        guard chars.count == 2 else { return nil }

        // Char 1 (main): left 55%, vertically centred
        let s1 = 0.55
        let dx1 = 0.0, dy1 = (1.0 - s1) / 2.0

        // Char 2 (small): 40%, placed to the right of char 1 with equal margins
        let s2 = 0.40
        let dx2 = s1 + (1.0 - s1 - s2) / 2.0
        let dy2 = (1.0 - s2) / 2.0

        var result: [[CGPoint]] = []

        if let paths1 = getStrokeOrder(String(chars[0])) {
            for path in paths1 {
                let pts = sampleSVGPath(path, scale: s1 / kanjivgSize)
                result.append(pts.map { CGPoint(x: $0.x + dx1, y: $0.y + dy1) })
            }
        }
        if let paths2 = getStrokeOrder(String(chars[1])) {
            for path in paths2 {
                let pts = sampleSVGPath(path, scale: s2 / kanjivgSize)
                result.append(pts.map { CGPoint(x: $0.x + dx2, y: $0.y + dy2) })
            }
        }

        return result.isEmpty ? nil : result
    }
}

// MARK: - SVG Path Point Sampler

/// Walks SVG path commands and samples points. Curves are approximated with 10 linear segments.
/// - Parameter scale: Applied to raw coordinates (pass 1/109 to normalise to [0,1]²).
private func sampleSVGPath(_ d: String, scale: Double) -> [CGPoint] {
    var points: [CGPoint] = []
    let tokens = tokenizePath(d)
    var idx = 0
    var cur = CGPoint.zero
    var lastCtrl: CGPoint? = nil
    var lastCmd: Character = "M"

    func nextVal() -> Double? {
        while idx < tokens.count && tokens[idx] == "," { idx += 1 }
        guard idx < tokens.count, let v = Double(tokens[idx]) else { return nil }
        idx += 1
        return v * scale
    }
    func nextPt() -> CGPoint? {
        guard let x = nextVal(), let y = nextVal() else { return nil }
        return CGPoint(x: x, y: y)
    }
    func abs(_ raw: CGPoint, rel: Bool) -> CGPoint {
        rel ? CGPoint(x: cur.x + raw.x, y: cur.y + raw.y) : raw
    }

    func sampleCubic(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) {
        for i in 0...10 {
            let t = Double(i) / 10.0
            let mt = 1 - t
            let x = mt*mt*mt*p0.x + 3*mt*mt*t*p1.x + 3*mt*t*t*p2.x + t*t*t*p3.x
            let y = mt*mt*mt*p0.y + 3*mt*mt*t*p1.y + 3*mt*t*t*p2.y + t*t*t*p3.y
            points.append(CGPoint(x: x, y: y))
        }
    }
    func sampleQuad(p0: CGPoint, c: CGPoint, p1: CGPoint) {
        for i in 0...10 {
            let t = Double(i) / 10.0
            let mt = 1 - t
            let x = mt*mt*p0.x + 2*mt*t*c.x + t*t*p1.x
            let y = mt*mt*p0.y + 2*mt*t*c.y + t*t*p1.y
            points.append(CGPoint(x: x, y: y))
        }
    }

    while idx < tokens.count {
        if tokens[idx].count == 1, let ch = tokens[idx].first, ch.isLetter {
            lastCmd = ch; idx += 1
        }
        let cmd = lastCmd
        let rel = cmd.isLowercase

        switch cmd.uppercased().first! {
        case "M":
            guard let raw = nextPt() else { break }
            let p = abs(raw, rel: rel)
            points.append(p); cur = p; lastCtrl = nil
            lastCmd = rel ? "l" : "L"
        case "L":
            guard let raw = nextPt() else { break }
            let p = abs(raw, rel: rel)
            points.append(p); cur = p; lastCtrl = nil
        case "H":
            guard let rawX = nextVal() else { break }
            let p = CGPoint(x: rel ? cur.x + rawX : rawX, y: cur.y)
            points.append(p); cur = p; lastCtrl = nil
        case "V":
            guard let rawY = nextVal() else { break }
            let p = CGPoint(x: cur.x, y: rel ? cur.y + rawY : rawY)
            points.append(p); cur = p; lastCtrl = nil
        case "C":
            guard let rc1 = nextPt(), let rc2 = nextPt(), let rEnd = nextPt() else { break }
            let c1 = abs(rc1, rel: rel), c2 = abs(rc2, rel: rel), end = abs(rEnd, rel: rel)
            sampleCubic(p0: cur, p1: c1, p2: c2, p3: end)
            lastCtrl = c2; cur = end
        case "S":
            guard let rc2 = nextPt(), let rEnd = nextPt() else { break }
            let c2 = abs(rc2, rel: rel), end = abs(rEnd, rel: rel)
            let c1 = lastCtrl.map { CGPoint(x: 2*cur.x - $0.x, y: 2*cur.y - $0.y) } ?? cur
            sampleCubic(p0: cur, p1: c1, p2: c2, p3: end)
            lastCtrl = c2; cur = end
        case "Q":
            guard let rc = nextPt(), let rEnd = nextPt() else { break }
            let c = abs(rc, rel: rel), end = abs(rEnd, rel: rel)
            sampleQuad(p0: cur, c: c, p1: end)
            lastCtrl = c; cur = end
        case "T":
            guard let rEnd = nextPt() else { break }
            let end = abs(rEnd, rel: rel)
            let c = lastCtrl.map { CGPoint(x: 2*cur.x - $0.x, y: 2*cur.y - $0.y) } ?? cur
            sampleQuad(p0: cur, c: c, p1: end)
            lastCtrl = c; cur = end
        case "Z":
            lastCtrl = nil
        default:
            idx += 1; continue
        }
    }

    return points
}

private func tokenizePath(_ d: String) -> [String] {
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
            tokens.append(current); current = "0."
        } else {
            current.append(ch)
        }
    }
    if !current.isEmpty { tokens.append(current) }
    return tokens
}

// MARK: - Resampling

/// Resamples a stroke to exactly `count` evenly-spaced points along the arc length.
private func resample(_ stroke: [CGPoint], count: Int = 64) -> [CGPoint] {
    guard stroke.count >= 2 else {
        guard let first = stroke.first else { return [] }
        return Array(repeating: first, count: count)
    }

    var cumLen: [Double] = [0]
    for i in 1..<stroke.count {
        let dx = stroke[i].x - stroke[i-1].x
        let dy = stroke[i].y - stroke[i-1].y
        cumLen.append(cumLen[i-1] + sqrt(dx*dx + dy*dy))
    }
    let total = cumLen.last!
    guard total > 0 else { return Array(repeating: stroke[0], count: count) }

    var result: [CGPoint] = []
    result.reserveCapacity(count)

    for i in 0..<count {
        let target = total * Double(i) / Double(count - 1)
        // Binary search for the segment containing target
        var lo = 0, hi = cumLen.count - 1
        while lo + 1 < hi {
            let mid = (lo + hi) / 2
            if cumLen[mid] <= target { lo = mid } else { hi = mid }
        }
        let segLen = cumLen[hi] - cumLen[lo]
        let t = segLen > 0 ? (target - cumLen[lo]) / segLen : 0.0
        result.append(CGPoint(
            x: stroke[lo].x + (stroke[hi].x - stroke[lo].x) * t,
            y: stroke[lo].y + (stroke[hi].y - stroke[lo].y) * t
        ))
    }
    return result
}

// MARK: - DTW

/// Dynamic Time Warping distance, normalised by path length.
private func dtw(_ a: [CGPoint], _ b: [CGPoint]) -> Double {
    let n = a.count, m = b.count
    guard n > 0, m > 0 else { return 0 }

    func dist(_ i: Int, _ j: Int) -> Double {
        let dx = a[i].x - b[j].x, dy = a[i].y - b[j].y
        return sqrt(dx*dx + dy*dy)
    }

    var dp = Array(repeating: Array(repeating: Double.infinity, count: m), count: n)
    dp[0][0] = dist(0, 0)
    for i in 1..<n { dp[i][0] = dp[i-1][0] + dist(i, 0) }
    for j in 1..<m { dp[0][j] = dp[0][j-1] + dist(0, j) }
    for i in 1..<n {
        for j in 1..<m {
            dp[i][j] = dist(i, j) + min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
        }
    }
    return dp[n-1][m-1] / Double(max(n, m))
}

// MARK: - Stroke Matching

private typealias StrokePair = (u: [CGPoint], r: [CGPoint])

/// Greedy nearest-match: repeatedly assigns the lowest-DTW-cost (user, reference) pair.
/// Returns matched pairs (in user draw order) and the reference indices in that order
/// (used to score stroke-order correctness).
private func matchStrokes(
    user: [[CGPoint]],
    reference: [[CGPoint]]
) -> (matches: [StrokePair], orderedRefIndices: [Int]) {
    let uResamp = user.map { resample($0) }
    let rResamp = reference.map { resample($0) }

    var pairs: [(cost: Double, ui: Int, ri: Int)] = []
    for (ui, u) in uResamp.enumerated() {
        for (ri, r) in rResamp.enumerated() {
            pairs.append((dtw(u, r), ui, ri))
        }
    }
    pairs.sort { $0.cost < $1.cost }

    var usedU = Set<Int>(), usedR = Set<Int>()
    var assignments: [(uIdx: Int, rIdx: Int)] = []
    for p in pairs {
        guard !usedU.contains(p.ui), !usedR.contains(p.ri) else { continue }
        assignments.append((p.ui, p.ri))
        usedU.insert(p.ui); usedR.insert(p.ri)
    }

    // Sort by draw order
    let sorted = assignments.sorted { $0.uIdx < $1.uIdx }
    let matches = sorted.map { (user[$0.uIdx], reference[$0.rIdx]) }
    let orderedRefIndices = sorted.map { $0.rIdx }
    return (matches, orderedRefIndices)
}

// MARK: - Grid-based Shape

/// Translate all strokes so the bounding box is centred, then scale so the largest
/// dimension spans [0,1]. Both user and reference are independently normalised into
/// this frame before grid comparison, so position and scale on the original canvas
/// don't affect the score.
private func normalizeToCharacterSpace(_ strokes: [[CGPoint]]) -> [[CGPoint]] {
    let all = strokes.flatMap { $0 }
    guard !all.isEmpty else { return strokes }
    let xs = all.map { Double($0.x) }, ys = all.map { Double($0.y) }
    let minX = xs.min()!, maxX = xs.max()!
    let minY = ys.min()!, maxY = ys.max()!
    let scale = Swift.max(maxX - minX, maxY - minY)
    guard scale > 0.001 else { return strokes }
    let cx = (minX + maxX) / 2, cy = (minY + maxY) / 2
    return strokes.map { s in s.map { p in
        CGPoint(x: (Double(p.x) - cx) / scale + 0.5,
                y: (Double(p.y) - cy) / scale + 0.5)
    }}
}

/// Rasterise strokes into an N×N grid of ink densities (normalised to sum 1).
/// Each stroke is densely resampled first so every cell it passes through is filled.
private func gridFeatures(_ strokes: [[CGPoint]], gridSize: Int = 8) -> [Double] {
    var grid = Array(repeating: 0.0, count: gridSize * gridSize)
    let n = Double(gridSize)
    for stroke in strokes {
        for pt in resample(stroke) {
            let col = Swift.min(Swift.max(Int(Double(pt.x) * n), 0), gridSize - 1)
            let row = Swift.min(Swift.max(Int(Double(pt.y) * n), 0), gridSize - 1)
            grid[row * gridSize + col] += 1.0
        }
    }
    let total = grid.reduce(0, +)
    return total > 0 ? grid.map { $0 / total } : grid
}

/// Cosine similarity between two grid vectors — 1.0 is identical, 0.0 is orthogonal.
private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
    let dot  = zip(a, b).reduce(0.0) { $0 + $1.0 * $1.1 }
    let normA = sqrt(a.reduce(0.0) { $0 + $1 * $1 })
    let normB = sqrt(b.reduce(0.0) { $0 + $1 * $1 })
    guard normA > 0, normB > 0 else { return 0 }
    return dot / (normA * normB)
}

/// Full grid-based shape score: normalise → rasterise → cosine similarity.
private func gridShapeScore(userStrokes: [[CGPoint]], refStrokes: [[CGPoint]]) -> Double {
    let uGrid = gridFeatures(normalizeToCharacterSpace(userStrokes))
    let rGrid = gridFeatures(normalizeToCharacterSpace(refStrokes))
    return cosineSimilarity(uGrid, rGrid)
}

// MARK: - Sub-scores

/// Compares each stroke's arc-length as a fraction of total ink.
/// A stroke that should be 40% of the drawing but is drawn as 80% scores low.
/// Unmatched reference strokes (user drew too few) drag down the average by
/// dividing by refCount rather than matches.count.
private func proportionScore(matches: [StrokePair], userStrokes: [[CGPoint]], refStrokes: [[CGPoint]]) -> Double {
    guard refStrokes.count > 1 else { return 1.0 }

    func arcLen(_ pts: [CGPoint]) -> Double {
        guard pts.count > 1 else { return 0 }
        return zip(pts, pts.dropFirst()).reduce(0.0) { acc, pair in
            let dx = Double(pair.1.x - pair.0.x), dy = Double(pair.1.y - pair.0.y)
            return acc + sqrt(dx * dx + dy * dy)
        }
    }

    let uTotal = userStrokes.map(arcLen).reduce(0, +)
    let rTotal = refStrokes.map(arcLen).reduce(0, +)
    guard uTotal > 0, rTotal > 0 else { return 1.0 }

    // Sum deviations over matched pairs; divide by refCount so missing strokes
    // (user drew too few) contribute implicit 0 vs their expected fraction.
    let devSum = matches.reduce(0.0) { acc, pair in
        acc + abs(arcLen(pair.u) / uTotal - arcLen(pair.r) / rTotal)
    }
    let avgDev = devSum / Double(refStrokes.count)

    return 1.0 / (1.0 + pow(avgDev / 0.20, 1.5))
}

/// Scores stroke order correctness with a count-mismatch penalty.
/// Drawing the wrong number of strokes reduces the score proportionally
/// (e.g. 1 stroke on a 5-stroke character caps the score at 0.2).
private func strokeOrderScore(orderedRefIndices: [Int], userCount: Int, refCount: Int) -> Double {
    guard refCount > 0, userCount > 0 else { return 0 }

    // Penalise for drawing too few or too many strokes
    let countPenalty = Double(min(userCount, refCount)) / Double(max(userCount, refCount))

    // Order correctness among matched strokes
    let orderScore: Double
    if orderedRefIndices.count <= 1 {
        orderScore = orderedRefIndices.isEmpty ? 0.0 : 1.0
    } else {
        var inOrder = 0
        for i in 1..<orderedRefIndices.count {
            if orderedRefIndices[i] > orderedRefIndices[i-1] { inOrder += 1 }
        }
        orderScore = Double(inOrder) / Double(orderedRefIndices.count - 1)
    }

    return orderScore * countPenalty
}
