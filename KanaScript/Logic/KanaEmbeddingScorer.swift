import CoreML
import CoreVideo
import UIKit

// MARK: - Result

struct QualityResult {
    let score: Float                 // 0–1
    let passed: Bool
    let strokeCountCorrect: Bool
    let referenceStrokeCount: Int
    let userStrokeCount: Int
}

// MARK: - Scorer

/// Singleton that scores user-drawn kana using a metric-learning embedding model.
///
/// The model produces a 128-d L2-normalized embedding. Quality is measured as
/// L2 distance from the user's embedding to the target character's prototype cluster.
///
/// Score = max(0, 1 − distance / radius)
///   where `radius` is the 95th-percentile distance computed over clean font renders.
final class KanaEmbeddingScorer {
    static let shared = KanaEmbeddingScorer()

    private let model: MLModel?
    private let prototypes: [String: Prototype]

    private struct Prototype {
        let vector: [Float]   // 128-d L2-normalized
        let radius: Float
    }

    private struct RawPrototype: Decodable {
        let prototype: [Float]
        let radius: Double
    }

    private static let canvasSize: Int = 64
    private static let passThreshold: Float = 0.50

    /// Scales the prototype radius to account for the gap between tightly-clustered
    /// font renders (used to compute the radius) and more variable real handwriting.
    /// Tune downward as the model improves and clusters tighten.
    private static let radiusScale: Float = 3.0

    private init() {
        if let url = Bundle.main.url(forResource: "KanaEmbedderModel", withExtension: "mlmodelc"),
           let loaded = try? MLModel(contentsOf: url) {
            model = loaded
        } else {
            model = nil
            print("[KanaEmbedder] ⚠️ KanaEmbedderModel.mlmodelc not found — embedding grading unavailable")
        }

        if let url = Bundle.main.url(forResource: "kana_prototypes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let raw = try? JSONDecoder().decode([String: RawPrototype].self, from: data) {
            prototypes = raw.mapValues { Prototype(vector: $0.prototype, radius: Float($0.radius)) }
            print("[KanaEmbedder] Loaded \(prototypes.count) prototypes")
        } else {
            prototypes = [:]
            print("[KanaEmbedder] ⚠️ kana_prototypes.json not found — embedding grading unavailable")
        }
    }

    // MARK: - Public API

    var isAvailable: Bool { model != nil && !prototypes.isEmpty }

    /// Embed `strokes` and compute a quality score against the target character's prototype.
    func qualityScore(
        strokes: [[CGPoint]],
        character: KanaCharacter,
        canvasSize: CGFloat
    ) -> QualityResult? {
        guard model != nil, !strokes.isEmpty else { return nil }
        guard let proto = prototypes[character.character] else {
            print("[KanaEmbedder] No prototype for '\(character.character)'")
            return nil
        }

        guard let pixelBuffer = renderToPixelBuffer(strokes: strokes, canvasSize: canvasSize) else {
            print("[KanaEmbedder] Render failed")
            return nil
        }

        let featureValue = MLFeatureValue(pixelBuffer: pixelBuffer)
        guard let provider = try? MLDictionaryFeatureProvider(dictionary: ["input": featureValue]) else {
            return nil
        }

        guard let output = try? model!.prediction(from: provider),
              let embFeature = output.featureValue(for: "embedding"),
              let multiArray = embFeature.multiArrayValue
        else {
            print("[KanaEmbedder] Prediction failed")
            return nil
        }

        let embedding = (0 ..< multiArray.count).map { multiArray[$0].floatValue }
        let dist = l2Distance(embedding, proto.vector)
        let effectiveRadius = proto.radius * KanaEmbeddingScorer.radiusScale
        let score = max(0.0, 1.0 - dist / effectiveRadius)

        let refCount = referenceStrokeCount(for: character)

        print("[KanaEmbedder] '\(character.character)' dist=\(String(format: "%.4f", dist)) radius=\(String(format: "%.4f", proto.radius))×\(KanaEmbeddingScorer.radiusScale)=\(String(format: "%.4f", effectiveRadius)) score=\(String(format: "%.3f", score))")

        return QualityResult(
            score: score,
            passed: score >= KanaEmbeddingScorer.passThreshold,
            strokeCountCorrect: refCount == 0 || strokes.count == refCount,
            referenceStrokeCount: refCount,
            userStrokeCount: strokes.count
        )
    }

    // MARK: - Rendering

    private func renderToPixelBuffer(strokes: [[CGPoint]], canvasSize: CGFloat) -> CVPixelBuffer? {
        let side = KanaEmbeddingScorer.canvasSize
        let outputSize = CGFloat(side)

        let allPoints = strokes.flatMap { $0 }
        guard !allPoints.isEmpty else { return nil }

        let xs = allPoints.map(\.x), ys = allPoints.map(\.y)
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let span = max(maxX - minX, maxY - minY, 1)

        let targetSpan = outputSize * 0.80
        let normScale = targetSpan / span
        let offsetX = (outputSize - (maxX - minX) * normScale) / 2 - minX * normScale
        let offsetY = (outputSize - (maxY - minY) * normScale) / 2 - minY * normScale

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.preferredRange = .standard
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: outputSize, height: outputSize),
            format: format
        )
        let uiImage = renderer.image { ctx in
            UIColor(white: 200.0 / 255.0, alpha: 1.0).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
            UIColor(white: 111.0 / 255.0, alpha: 1.0).setStroke()
            ctx.cgContext.setLineWidth(5.0)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)

            for stroke in strokes {
                guard stroke.count >= 2 else { continue }
                ctx.cgContext.beginPath()
                ctx.cgContext.move(to: CGPoint(
                    x: stroke[0].x * normScale + offsetX,
                    y: stroke[0].y * normScale + offsetY
                ))
                for pt in stroke.dropFirst() {
                    ctx.cgContext.addLine(to: CGPoint(
                        x: pt.x * normScale + offsetX,
                        y: pt.y * normScale + offsetY
                    ))
                }
                ctx.cgContext.strokePath()
            }
        }

        guard let cgImage = uiImage.cgImage else { return nil }

        // Allocate a grayscale CVPixelBuffer and draw the CGImage into it directly.
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            side,
            side,
            kCVPixelFormatType_OneComponent8,
            nil,
            &pixelBuffer
        )
        guard let pb = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }

        guard let base = CVPixelBufferGetBaseAddress(pb) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pb)

        guard let drawCtx = CGContext(
            data: base,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        drawCtx.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
        return pb
    }

    // MARK: - Reference stroke count

    private func referenceStrokeCount(for character: KanaCharacter) -> Int {
        let str = character.character
        if str.count == 1 { return getStrokeOrder(str)?.count ?? 0 }
        let chars = Array(str)
        guard chars.count == 2 else { return 0 }
        return chars.compactMap { getStrokeOrder(String($0))?.count }.reduce(0, +)
    }

    // MARK: - Math

    private func l2Distance(_ a: [Float], _ b: [Float]) -> Float {
        zip(a, b).map { ($0 - $1) * ($0 - $1) }.reduce(0, +).squareRoot()
    }
}
