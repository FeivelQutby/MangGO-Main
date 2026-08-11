import Foundation

/// Rerata HSV kulit buah memakai konvensi OpenCV: H 0...179, S dan V 0...255.
struct ColorProfile: Codable, Hashable, Sendable {
    var hue: Double
    var saturation: Double
    var brightness: Double
    var blushCoverage: Percentage
}
