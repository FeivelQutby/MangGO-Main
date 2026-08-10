import Foundation
import CoreGraphics

struct MockDefectDetector: DefectDetecting {
    var observations: [DefectObservation] = .moderate
    var latency: Duration = .milliseconds(600)

    func detect(in input: VisionInput) async throws -> [DefectObservation] {
        try await Task.sleep(for: latency)
        return observations
    }
}

extension Array where Element == DefectObservation {
    static let clean: [DefectObservation] = []

    static let moderate: [DefectObservation] = [
        DefectObservation(
            boundingBox: CGRect(x: 0.34, y: 0.46, width: 0.09, height: 0.07),
            confidence: 0.81
        ),
        DefectObservation(
            boundingBox: CGRect(x: 0.58, y: 0.63, width: 0.05, height: 0.04),
            confidence: 0.64
        )
    ]

    static let severe: [DefectObservation] = [
        DefectObservation(
            boundingBox: CGRect(x: 0.24, y: 0.28, width: 0.34, height: 0.30),
            confidence: 0.92
        )
    ]
}
