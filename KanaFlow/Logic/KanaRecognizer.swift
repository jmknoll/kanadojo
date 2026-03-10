import CoreML
import UIKit

/// Singleton that classifies user-drawn kana strokes using the on-device CNN.
///
/// Preprocessing contract (must match Python training pipeline exactly):
///   - Canvas: 64×64 grayscale
///   - Ink: dark (stroke pixels), background: white (255)
///   - Normalisation: pixel_value / 255.0 → Float32 in [0, 1]
///   - Input tensor shape: (1, 1, 64, 64)  [batch, channel, height, width]
final class KanaRecognizer {
    static let shared = KanaRecognizer()

    private let model: MLModel?
    private let labels: [String]

    private static let canvasSize: Int = 64
    private static let passingThreshold: Float = 0.65

    private init() {
        // Load labels from embedded JSON
        if let url = Bundle.main.url(forResource: "kana_labels", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            labels = decoded
        } else {
            labels = []
            print("[KanaRecognizer] ⚠️ Failed to load kana_labels.json from bundle")
        }

        // Load Core ML model — Xcode compiles .mlpackage → .mlmodelc at build time
        if let url = Bundle.main.url(forResource: "KanaClassifier", withExtension: "mlmodelc"),
           let loaded = try? MLModel(contentsOf: url) {
            model = loaded
        } else {
            model = nil
            print("[KanaRecognizer] ⚠️ Failed to load KanaClassifier.mlmodelc from bundle")
        }
    }

    // MARK: - Public API

    /// Classify a user's strokes drawn on a canvas of the given size.
    ///
    /// - Parameters:
    ///   - strokes: Raw stroke points in [0, canvasSize]² space.
    ///   - character: The target kana character (used to look up the correct class index).
    ///   - canvasSize: Side length of the drawing canvas in points.
    /// - Returns: Probability [0, 1] that the drawing matches the target character,
    ///   or `nil` if the model is unavailable or classification fails.
    func classify(strokes: [[CGPoint]], character: KanaCharacter, canvasSize: CGFloat) -> Float? {
        guard let model, !labels.isEmpty else { return nil }
        guard let targetIdx = labels.firstIndex(of: character.character) else { return nil }

        print("[KanaRecognizer] classifying '\(character.character)': \(strokes.count) strokes, \(strokes.map(\.count).reduce(0,+)) points, canvasSize=\(canvasSize)")
        guard let bitmap = renderToBitmap(strokes: strokes, canvasSize: canvasSize) else { return nil }
        guard let input = makeMLInput(bitmap: bitmap) else { return nil }

        guard let output = try? model.prediction(from: input) else {
            print("[KanaRecognizer] prediction failed")
            return nil
        }

        // Debug: print all available output feature names
        print("[KanaRecognizer] output features: \(output.featureNames)")

        guard let probsFeature = output.featureValue(for: "classLabelProbs"),
              let multiArray = probsFeature.multiArrayValue
        else {
            print("[KanaRecognizer] 'classLabelProbs' not found in output")
            return nil
        }

        // Debug: print shape and top-5 probabilities
        print("[KanaRecognizer] multiArray shape: \(multiArray.shape), count: \(multiArray.count)")
        let probs = (0 ..< multiArray.count).map { multiArray[$0].floatValue }
        let top5 = probs.enumerated().sorted { $0.element > $1.element }.prefix(5)
        print("[KanaRecognizer] top-5: \(top5.map { "\(labels.indices.contains($0.offset) ? labels[$0.offset] : "?")(idx=\($0.offset))=\(String(format: "%.3f", $0.element))" })")
        print("[KanaRecognizer] target '\(character.character)' idx=\(targetIdx) prob=\(probs[targetIdx])")

        return probs[targetIdx]
    }

    // MARK: - Rendering

    private func renderToBitmap(strokes: [[CGPoint]], canvasSize: CGFloat) -> CGImage? {
        let outputSize = CGFloat(KanaRecognizer.canvasSize)  // 64
        let size = CGSize(width: outputSize, height: outputSize)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.preferredRange = .standard

        // Normalise strokes to fill the output canvas (matching ETL layout where
        // the character fills the full image). Pad to 80% of output size so there
        // is a small margin around the character.
        let allPoints = strokes.flatMap { $0 }
        guard !allPoints.isEmpty else { return nil }

        let xs = allPoints.map(\.x), ys = allPoints.map(\.y)
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let spanX = maxX - minX, spanY = maxY - minY
        let span = max(spanX, spanY, 1)

        let targetSpan = outputSize * 0.80   // character fills 80% of the output
        let normScale = targetSpan / span
        let offsetX = (outputSize - spanX * normScale) / 2 - minX * normScale
        let offsetY = (outputSize - spanY * normScale) / 2 - minY * normScale

        // ETL training images: ink ~111/255, background ~200/255.
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { ctx in
            UIColor(white: 200.0 / 255.0, alpha: 1.0).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            UIColor(white: 111.0 / 255.0, alpha: 1.0).setStroke()
            ctx.cgContext.setLineWidth(5.0)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)

            for stroke in strokes {
                guard stroke.count >= 2 else { continue }
                ctx.cgContext.beginPath()
                let first = stroke[0]
                ctx.cgContext.move(to: CGPoint(x: first.x * normScale + offsetX,
                                               y: first.y * normScale + offsetY))
                for pt in stroke.dropFirst() {
                    ctx.cgContext.addLine(to: CGPoint(x: pt.x * normScale + offsetX,
                                                      y: pt.y * normScale + offsetY))
                }
                ctx.cgContext.strokePath()
            }
        }

        return image.cgImage
    }

    // MARK: - MLInput

    private func makeMLInput(bitmap: CGImage) -> MLDictionaryFeatureProvider? {
        let side = KanaRecognizer.canvasSize
        guard let pixelData = extractGrayscalePixels(from: bitmap, width: side, height: side) else {
            return nil
        }

        // Build (1, 1, 64, 64) MLMultiArray — shape: [batch, channel, height, width]
        guard let array = try? MLMultiArray(shape: [1, 1, side as NSNumber, side as NSNumber],
                                            dataType: .float32)
        else { return nil }

        let minPx = pixelData.min() ?? 255
        let darkCount = pixelData.filter { $0 < 128 }.count
        print("[KanaRecognizer] pixels: min=\(minPx) darkPixels=\(darkCount)/\(side*side)")

        for i in 0 ..< side * side {
            // pixelData is uint8 [0,255]: 0=black ink, 255=white background
            let normalised = Float(pixelData[i]) / 255.0
            array[i] = NSNumber(value: normalised)
        }

        let featureValue = MLFeatureValue(multiArray: array)
        guard let provider = try? MLDictionaryFeatureProvider(dictionary: ["input": featureValue]) else {
            return nil
        }
        return provider
    }

    private func extractGrayscalePixels(from cgImage: CGImage, width: Int, height: Int) -> [UInt8]? {
        var pixels = [UInt8](repeating: 255, count: width * height)
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }
}
