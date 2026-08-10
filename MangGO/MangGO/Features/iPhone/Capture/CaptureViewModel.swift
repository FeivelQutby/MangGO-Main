import Foundation
import Observation

@Observable
@MainActor
final class CaptureViewModel {
    enum Phase: Equatable {
        case starting
        case accessDenied
        case ready
        case analyzing
        case finished
    }

    private(set) var phase: Phase = .starting
    private(set) var sample = MangoSample()
    private(set) var result: GradeResult?
    private(set) var errorMessage: String?

    let camera: CameraSession

    private let detector: any DefectDetecting
    private let segmenter: any FruitSegmenting
    private let engine: GradingEngine

    /// `nonisolated` supaya bisa dipakai sebagai default argument dan property
    /// initializer, yang selalu dievaluasi di luar isolasi MainActor.
    nonisolated init(
        detector: any DefectDetecting = MockDefectDetector(),
        segmenter: any FruitSegmenting = MockFruitSegmenter(),
        engine: GradingEngine = GradingEngine(),
        camera: CameraSession = CameraSession()
    ) {
        self.detector = detector
        self.segmenter = segmenter
        self.engine = engine
        self.camera = camera
    }

    var detections: [DefectObservation] {
        sample.defects
    }

    func startCamera() async {
        guard await CameraSession.requestAccess() else {
            phase = .accessDenied
            return
        }

        do {
            try await camera.start()
            phase = .ready
        } catch {
            errorMessage = error.localizedDescription
            phase = .accessDenied
        }
    }

    func stopCamera() {
        camera.stop()
    }

    func analyze() async {
        guard phase == .ready || phase == .finished else { return }

        phase = .analyzing
        errorMessage = nil

        let input = camera.latestFrame.map(VisionInput.pixelBuffer) ?? .unavailable

        do {
            async let detected = detector.detect(in: input)
            async let area = segmenter.fruitAreaRatio(in: input)

            sample.defects = try await detected
            sample.fruitAreaRatio = try await area
            result = engine.evaluate(sample)
            phase = .finished
        } catch {
            errorMessage = error.localizedDescription
            phase = .ready
        }
    }

    func reset() {
        sample = MangoSample()
        result = nil
        errorMessage = nil
        phase = .ready
    }
}
