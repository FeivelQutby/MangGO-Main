import Foundation

struct Dimensions: Codable, Hashable, Sendable {
    var length: Millimeters
    var width: Millimeters
    var height: Millimeters

    /// Pendekatan elipsoid: (π/6) · p · l · t, dikonversi dari mm³ ke cm³.
    var volume: CubicCentimeters {
        (.pi / 6) * length * width * height / 1_000
    }
}
