import Foundation
import Vision
import CoreML

/// Deteksi bintik on-device lewat Core ML.
///
/// Belum aktif: `MangoDefect.mlpackage` belum ada di Resources. Versi model
/// Roboflow saat ini memakai arsitektur hosted-only, jadi dataset perlu
/// di-train ulang sebagai YOLOv11n atau RF-DETR-nano lalu di-export ke Core ML.
///
/// Actor, bukan struct, karena `VNCoreMLModel` tidak dijamin aman diakses dari
/// beberapa thread sekaligus.
actor CoreMLDefectDetector: DefectDetecting {
    private let confidenceThreshold: Float

    init(confidenceThreshold: Float = 0.40) {
        self.confidenceThreshold = confidenceThreshold
    }

    func detect(in input: VisionInput) async throws -> [DefectObservation] {
        throw VisionError.modelUnavailable
    }

    private func handler(for input: VisionInput) throws -> VNImageRequestHandler {
        switch input {
        case .pixelBuffer(let buffer):
            return VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right)
        case .image(let image):
            return VNImageRequestHandler(cgImage: image, orientation: .up)
        case .unavailable:
            throw VisionError.noImage
        }
    }

    private func observations(from request: VNRequest) -> [DefectObservation] {
        let results = request.results as? [VNRecognizedObjectObservation] ?? []
        return results.compactMap { result in
            guard let top = result.labels.first, top.confidence >= confidenceThreshold else {
                return nil
            }
            return DefectObservation(
                boundingBox: result.boundingBox,
                confidence: top.confidence,
                label: top.identifier
            )
        }
    }
}
