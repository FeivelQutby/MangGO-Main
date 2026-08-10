import Foundation
import Vision
import CoreML

/// On-device defect detection.
///
/// The model is loaded from the app bundle by name at runtime, so dropping
/// `MangoDefect.mlpackage` into `Core/Vision/Resources/` activates this detector
/// without any code change. Until then `detect` throws `.modelUnavailable`.
///
/// An actor because `VNCoreMLModel` is not documented as thread-safe.
actor CoreMLDefectDetector: DefectDetecting {
    private let modelName: String
    private let confidenceThreshold: Float
    private var loadedModel: VNCoreMLModel?

    init(modelName: String = "MangoDefect", confidenceThreshold: Float = 0.40) {
        self.modelName = modelName
        self.confidenceThreshold = confidenceThreshold
    }

    func detect(in input: VisionInput) async throws -> [DefectObservation] {
        let model = try loadModel()
        let handler = try makeHandler(for: input)

        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .scaleFill

        do {
            try handler.perform([request])
        } catch {
            throw VisionError.inferenceFailed(error)
        }

        return observations(from: request)
    }

    private func loadModel() throws -> VNCoreMLModel {
        if let loadedModel { return loadedModel }

        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw VisionError.modelUnavailable
        }

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndNeuralEngine

        do {
            let model = try VNCoreMLModel(for: MLModel(contentsOf: url, configuration: configuration))
            loadedModel = model
            return model
        } catch {
            throw VisionError.inferenceFailed(error)
        }
    }

    private func makeHandler(for input: VisionInput) throws -> VNImageRequestHandler {
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
