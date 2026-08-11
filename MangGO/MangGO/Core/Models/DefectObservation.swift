import Foundation
import CoreGraphics

struct DefectObservation: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()

    /// Ternormalisasi 0...1 dalam koordinat Vision (origin kiri-bawah).
    var boundingBox: CGRect
    var confidence: Float
    var label = "defect"

    /// Luas kotak relatif terhadap luas frame.
    var frameAreaRatio: Double {
        Double(boundingBox.width * boundingBox.height)
    }
}
