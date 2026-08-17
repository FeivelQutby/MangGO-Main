import Foundation
import Observation
import Combine
import CoreVideo

enum MeasurementPhase {
    case idle
    case capturingPhoto1
    case waitingForFlip
    case waitingForMeasurement
    case capturingPhoto2
    case processing
    case finished
}

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
    private(set) var measurementPhase: MeasurementPhase = .idle
    private(set) var sample = MangoSample()
    private(set) var result: GradeResult?
    private(set) var errorMessage: String?
    
    /// Deteksi yang dibuang karena jatuh di latar, bukan di kulit buah. Angka
    /// ini yang membuktikan filter mask sedang bekerja — kalau selalu 0 padahal
    /// isi kotak ramai, kemungkinan besar isolasi buah tidak jalan.
    private(set) var rejectedDetections = 0
    
    let camera: CameraSession
    
    private let pipeline: DefectPipeline
    private let engine: GradingEngine
    
    private var ble: BLEManager?
    private var cancellables = Set<AnyCancellable>()
    
    
    @ObservationIgnored
    private var photo1: CVPixelBuffer?
    @ObservationIgnored
    private var photo2: CVPixelBuffer?
    
    private var photo1Captured = false
    private var photo2Captured = false
    private var measurementReceived = false
    
    private var loadCellReady = false
    private var servoReady = false
    
    /// Tidak ikut dilacak Observation: ini kanal keluar, bukan state UI.
    /// Referensi kuat aman karena `StationSync` tidak pernah menunjuk balik
    /// ke view model, jadi tidak ada retain cycle.
    @ObservationIgnored private var station: StationSync?
    @ObservationIgnored private var counts: [String: Int] = [:]
    
    /// `nonisolated` supaya bisa dipakai sebagai default argument dan property
    /// initializer, yang selalu dievaluasi di luar isolasi MainActor.
    nonisolated init(
        detector: any DefectDetecting = MockDefectDetector(),
        isolator: any FruitIsolating = DefectDetectorFactory.makeIsolator(),
        engine: GradingEngine = GradingEngine(),
        camera: CameraSession = CameraSession()
    ) {
        self.pipeline = DefectPipeline(isolator: isolator, detector: detector)
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
        
        // Camera
        switch phase {
        case .starting:
            sensors.camera = .waiting
            
        case .accessDenied:
            sensors.camera = .offline
            
        case .ready, .analyzing, .finished:
            sensors.camera = .ready
        }
        
        // Bluetooth
        sensors.bluetooth =
        ble?.isConnected == true
        ? .ready
        : .offline
        
        
        // Load Cell
        sensors.loadCell =
        loadCellReady
        ? .ready
        : .offline
        
        
        // Servo
        sensors.servo =
        servoReady
        ? .ready
        : .offline
        
        return sensors
    }
    
    private func stationResult(from result: GradeResult) -> StationSnapshot.Result {
        StationSnapshot.Result(
            id: result.id,
            grade: result.grade.displayCode,
            reason: result.disqualificationReason ?? result.limitingFactors.first.map {
                "\($0.indicator.displayName): \($0.detail)"
            },
            score: result.totalScore,
            weightGrams: sample.mass,
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
    
    /// Membekukan exposure dan white balance. Dipanggil operator sebelum batch
    /// supaya pembacaan warna antar buah bisa dibandingkan.
    func lockColorSettings() {
        camera.lockColorSettings()
    }
    
    func analyze() async {
        
        guard phase == .ready || phase == .finished else {
            return
        }
        
        phase = .analyzing
        errorMessage = nil
        
        publish(.scanningFront)
        
        let input: VisionInput
        
        if let photo2 {
            print("📸 Analyzing Photo 2")
            input = VisionInput.pixelBuffer(photo2)
        } else if let currentFrame = camera.latestFrame {
            print("📸 No Photo 2 — analyzing current camera frame")
            input = VisionInput.pixelBuffer(currentFrame)
        } else {
            print("❌ No camera frame available")
            phase = .ready
            publish(.idle)
            return
        }
        
        do {
            
            let analysis = try await pipeline.analyze(input)
            
            // MARK: - Defect Analysis
            
            print("🔍 DEFECT ANALYSIS")
            print("Defects detected: \(analysis.defects.count)")
            print(
                "Fruit area ratio: " +
                String(
                    format: "%.2f%%",
                    analysis.fruitAreaRatio * 100
                )
            )
            print(
                "Rejected detections: \(analysis.rejectedDetections)"
            )
            
            for (index, defect) in analysis.defects.enumerated() {
                
                print("Defect #\(index + 1)")
                print("Label: \(defect.label)")
                print(
                    "Confidence: " +
                    String(
                        format: "%.1f%%",
                        defect.confidence * 100
                    )
                )
                print(
                    "Area ratio: " +
                    String(
                        format: "%.2f%%",
                        defect.frameAreaRatio * 100
                    )
                )
                print("Bounding box: \(defect.boundingBox)")
                print("--------------------")
            }
            
            // MARK: - Update Sample
            
            sample.defects = analysis.defects
            sample.fruitAreaRatio = analysis.fruitAreaRatio
            sample.color = analysis.color
            
            rejectedDetections =
            analysis.rejectedDetections
            
            // MARK: - Grading
            
            let evaluated = engine.evaluate(sample)
            
            result = evaluated
            phase = .finished
            
            if let evaluated {
                
                print("🎯 GRADING RESULT")
                print(
                    "Grade: \(evaluated.grade.displayCode)"
                )
                
                print("Limiting factors:")
                
                for factor in evaluated.limitingFactors {
                    
                    print(
                        "- \(factor.indicator.displayName)"
                    )
                    
                    print(
                        "  \(factor.detail)"
                    )
                }
                
                counts[
                    evaluated.grade.displayCode,
                    default: 0
                ] += 1
                
                publish(
                    .done,
                    result: stationResult(
                        from: evaluated
                    )
                )
                
            } else {
                
                print("⚠️ No grade result")
                
                publish(.idle)
            }
            
        } catch {
            
            errorMessage =
            error.localizedDescription
            
            phase = .ready
            
            publish(.idle)
        }
    }
    
    func reset() {
        sample = MangoSample()
        result = nil
        errorMessage = nil
        rejectedDetections = 0
        phase = .ready
        publish(.idle)
    }
    
    func attachBLE(_ ble: BLEManager) {
        self.ble = ble
        
        ble.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] connected in
                
                guard let self else {
                    return
                }
                
                print(
                    connected
                    ? "🔵 BLE connected"
                    : "⚫️ BLE disconnected"
                )
                
                self.publish(.idle)
            }
            .store(in: &cancellables)
        
        ble.$lastMeasurement
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] measurement in
                
                guard let self else {
                    return
                }
                
                print("⚖️ Load cell ready")
                print("Weight: \(measurement.weight) g")
                
                self.sample.mass = measurement.weight
                self.measurementReceived = true
                
                self.publish(.idle)
            }
            .store(in: &cancellables)
        
        ble.$lastEvent
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                
                guard let self else {
                    return
                }
                
                self.handleBLEEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleBLEEvent(_ event: BLEEvent) {
        
        print("📦 BLE EVENT: \(event)")
        
        switch event {
            
        case .loadCellReady:
            
            loadCellReady = true
            
            print("⚖️ Load Cell READY")
            
            publish(.idle)
            
            
        case .servoReady:
            
            servoReady = true
            
            print("⚙️ Servo READY")
            
            publish(.idle)
            
        case .measurementStarted:
            
            photo1Captured = false
            photo2Captured = false
            measurementReceived = false
            
            photo1 = nil
            photo2 = nil
            
            measurementPhase = .capturingPhoto1
            phase = .ready
            
            print("🚀 Measurement started")
            
            
        case .capture1:
            
            measurementPhase = .capturingPhoto1
            
            print("📸 Capture 1 requested")
            
            Task {
                await capturePhoto1()
            }
            
            
        case .capture2:
            
            measurementPhase = .capturingPhoto2
            
            print("📸 Capture 2 requested")
            
            Task {
                await capturePhoto2()
            }
            
            
        case .measurement(let measurement):
            
            print("⚖️ MEASUREMENT RECEIVED")
            print("Weight: \(measurement.weight) g")
            
            sample.mass = measurement.weight
            measurementReceived = true
            
            measurementPhase = .capturingPhoto2
            
        case .measurementComplete:
            
            print("✅ Measurement complete")
            
            print("""
            Photo 1: \(photo1Captured)
            Photo 2: \(photo2Captured)
            Weight: \(measurementReceived)
            """)
            
            guard photo1Captured,
                  photo2Captured,
                  measurementReceived
            else {
                print("⚠️ Cannot analyze yet")
                return
            }
            
            measurementPhase = .processing
            
            Task {
                await analyze()
            }
        }
    }
    
    private func capturePhoto1() async {
        
        print("📸 Taking photo 1...")
        
        guard let frame = camera.latestFrame else {
            print("❌ No camera frame")
            return
        }
        
        photo1 = frame
        photo1Captured = true
        measurementPhase = .waitingForFlip
        print("📸 Photo 1 captured")
        
        ble?.sendCommand("PHOTO_1_DONE")    }
    
    private func capturePhoto2() async {
        
        print("📸 Taking photo 2...")
        
        guard let frame = camera.latestFrame else {
            print("❌ No camera frame")
            return
        }
        
        photo2 = frame
        photo2Captured = true
        print("📸 Photo 2 captured")
        ble?.sendCommand("PHOTO_2_DONE")    }
}
