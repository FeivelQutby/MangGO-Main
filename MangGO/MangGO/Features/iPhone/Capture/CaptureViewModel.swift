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

    /// Tidak ikut dilacak Observation: ini kanal keluar, bukan state UI.
    /// Referensi kuat aman karena `StationSync` tidak pernah menunjuk balik
    /// ke view model, jadi tidak ada retain cycle.
    @ObservationIgnored private var station: StationSync?
    @ObservationIgnored private var counts: [String: Int] = [:]

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

    // MARK: - Link ke iPad

    /// Dipanggil dari `iPhoneView`. Publish pertama yang membuat iPad keluar
    /// dari `DisconnectedScreen` begitu link terbentuk.
    func attach(to sync: StationSync) {
        guard station !== sync else { return }
        station = sync
        publish(.idle)
    }

    /// Selalu kirim snapshot utuh, bukan delta. Kalau satu paket hilang atau
    /// iPad baru menyambung di tengah batch, snapshot berikutnya langsung
    /// memperbaiki seluruh tampilan.
    private func publish(_ stationPhase: StationSnapshot.Phase,
                         result stationResult: StationSnapshot.Result? = nil) {
        guard let station else { return }
        station.publish(
            StationSnapshot(
                phase: stationPhase,
                lastResult: stationResult ?? station.snapshot.lastResult,
                counts: counts,
                sensors: currentSensors,
                updatedAt: .now
            )
        )
    }

    /// Load cell, ToF, dan Bluetooth masih `.offline` karena layer BLE belum
    /// ada. Lebih baik jujur di dashboard daripada memalsukan `.ready`.
    private var currentSensors: StationSnapshot.Sensors {
        var sensors = StationSnapshot.Sensors()
        switch phase {
        case .starting: sensors.camera = .waiting
        case .accessDenied: sensors.camera = .offline
        case .ready, .analyzing, .finished: sensors.camera = .ready
        }
        return sensors
    }

    private func stationResult(from result: GradeResult) -> StationSnapshot.Result {
        StationSnapshot.Result(
            grade: result.grade.displayCode,
            reason: result.limitingFactors.first.map {
                "\($0.indicator.displayName): \($0.detail)"
            },
            weightGrams: sample.mass,
            volumeCm3: sample.volume,
            blushPercent: sample.color?.blushCoverage,
            defectPercent: sample.spotCoverage,
            gradedAt: result.evaluatedAt
        )
    }

    // MARK: - Siklus

    func startCamera() async {
        guard await CameraSession.requestAccess() else {
            phase = .accessDenied
            publish(.idle)
            return
        }

        do {
            try await camera.start()
            phase = .ready
        } catch {
            errorMessage = error.localizedDescription
            phase = .accessDenied
        }
        publish(.idle)
    }

    func stopCamera() {
        camera.stop()
    }

    func analyze() async {
        guard phase == .ready || phase == .finished else { return }

        phase = .analyzing
        errorMessage = nil
        publish(.scanningFront)

        let input = camera.latestFrame.map(VisionInput.pixelBuffer) ?? .unavailable

        do {
            async let detected = detector.detect(in: input)
            async let area = segmenter.fruitAreaRatio(in: input)

            sample.defects = try await detected
            sample.fruitAreaRatio = try await area

            let evaluated = engine.evaluate(sample)
            result = evaluated
            phase = .finished

            if let evaluated {
                counts[evaluated.grade.displayCode, default: 0] += 1
                publish(.done, result: stationResult(from: evaluated))
            } else {
                // Tidak ada indikator yang terisi; jangan tampilkan grade palsu.
                publish(.idle)
            }
        } catch {
            errorMessage = error.localizedDescription
            phase = .ready
            publish(.idle)
        }
    }

    func reset() {
        sample = MangoSample()
        result = nil
        errorMessage = nil
        phase = .ready
        publish(.idle)
    }
}
