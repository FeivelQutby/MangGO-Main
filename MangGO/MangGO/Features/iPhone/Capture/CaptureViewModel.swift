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

    /// Area mangkuk pada frame "bawah" (photo2), koordinat Vision ternormalisasi
    /// (origin kiri-bawah). Dipakai sebagai crop cadangan foto SISI B saat Vision
    /// gagal mengisolasi mangga yang jauh. Rig tetap, jadi posisinya konsisten —
    /// GESER 4 angka ini kalau framing mangkuk belum pas (x,y = pojok kiri-bawah
    /// kotak; width,height = ukuran; semua fraksi 0…1).
    static let bowlFallbackCrop = CGRect(x: 0.12, y: 0.48, width: 0.52, height: 0.42)

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

        // Foto reject hanya ikut di snapshot hasil (`stationResult` != nil).
        // Saat snapshot dibawa maju ke fase berikutnya, buang gambarnya supaya
        // tidak dikirim ulang berkali-kali — iPad sudah menyimpannya di `.done`.
        let carried: StationSnapshot.Result?
        if let stationResult {
            carried = stationResult
        } else if var previous = station.snapshot.lastResult {
            previous.imageA = nil
            previous.imageB = nil
            carried = previous
        } else {
            carried = nil
        }

        station.publish(
            StationSnapshot(
                phase: stationPhase,
                lastResult: carried,
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
    
    private func stationResult(
        from result: GradeResult,
        imageA: Data? = nil,
        imageB: Data? = nil
    ) -> StationSnapshot.Result {
        StationSnapshot.Result(
            id: result.id,
            grade: result.grade.displayCode,
            reason: result.disqualificationReason ?? result.limitingFactors.first.map {
                "\($0.indicator.displayName): \($0.detail)"
            },
            score: result.totalScore,
            weightGrams: sample.mass,
            defectPercent: sample.spotCoverage,
            gradedAt: result.evaluatedAt,
            imageA: imageA,
            imageB: imageB
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
        
        // Kedua sisi dianalisis, bukan hanya photo2. photo1 = capture 1 ("atas",
        // mangga di cradle, dekat kamera), photo2 = capture 2 ("bawah", di
        // mangkuk, lebih jauh). Grade akhir diambil dari sisi TERBURUK, jadi:
        //  - bintik di sisi mana pun ikut menentukan grade, dan
        //  - kalau satu sisi gagal deteksi (mis. "bawah" terlalu jauh), sisi
        //    lain tetap memberi grade, bukan menggagalkan seluruh siklus.
        var sides: [(name: String, input: VisionInput)] = []
        if let photo1 { sides.append((name: "atas", input: .pixelBuffer(photo1))) }
        if let photo2 { sides.append((name: "bawah", input: .pixelBuffer(photo2))) }
        if sides.isEmpty, let frame = camera.latestFrame {
            sides.append((name: "live", input: .pixelBuffer(frame)))
        }

        guard !sides.isEmpty else {
            print("❌ No camera frame available")
            phase = .ready
            publish(.idle)
            return
        }

        // Evaluasi tiap sisi jadi kandidat grade. Sisi yang buahnya tidak
        // terdeteksi (`fruitNotFound`) dilewati, tidak menggagalkan yang lain.
        var candidates: [(sample: MangoSample, result: GradeResult, rejected: Int)] = []

        for side in sides {
            do {
                let analysis = try await pipeline.analyze(side.input)

                var sided = sample                     // bawa id, capturedAt, mass
                sided.defects = analysis.defects
                sided.fruitAreaRatio = analysis.fruitAreaRatio
                sided.color = analysis.color

                let spot = sided.spotCoverage ?? 0
                print("🔍 Sisi \(side.name): \(analysis.defects.count) bintik, " +
                      "area \(String(format: "%.1f%%", analysis.fruitAreaRatio * 100)), " +
                      "spot \(String(format: "%.1f%%", spot)), " +
                      "buang \(analysis.rejectedDetections)")

                guard let graded = engine.evaluate(sided) else { continue }
                candidates.append((sided, graded, analysis.rejectedDetections))
            } catch {
                print("⚠️ Sisi \(side.name) gagal dianalisis: \(error.localizedDescription)")
            }
        }

        // Tidak ada satu sisi pun yang berhasil → jangan buat grade palsu.
        guard let chosen = candidates.max(by: { lhs, rhs in
            if lhs.result.grade.rank != rhs.result.grade.rank {
                return lhs.result.grade.rank < rhs.result.grade.rank   // rank besar = lebih buruk
            }
            return (lhs.sample.spotCoverage ?? 0) < (rhs.sample.spotCoverage ?? 0)
        }) else {
            errorMessage = VisionError.fruitNotFound.errorDescription
            phase = .ready
            publish(.idle)
            return
        }

        // Sisi terburuk menentukan grade akhir (fusi worst-of).
        sample = chosen.sample
        result = chosen.result
        rejectedDetections = chosen.rejected
        phase = .finished

        let evaluated = chosen.result

        print("🎯 GRADING RESULT (worst-of \(candidates.count) sisi)")
        print("Grade: \(evaluated.grade.displayCode)")
        for factor in evaluated.limitingFactors {
            print("- \(factor.indicator.displayName): \(factor.detail)")
        }

        counts[evaluated.grade.displayCode, default: 0] += 1

        // Foto dokumentasi hanya untuk mangga reject: satu per sisi, dari kedua
        // capture asli (sisi A = depan/photo1, sisi B = belakang/photo2).
        var imageA: Data? = nil
        var imageB: Data? = nil

        if evaluated.grade == .rejected {
            // Frame live dipakai sebagai cadangan untuk sisi mana pun yang
            // capture-nya tidak sempat masuk. Sengaja BUKAN "sisi B jatuh ke
            // input sisi A": itu menghasilkan dua berkas identik yang terlihat
            // seperti dokumentasi dua sisi padahal isinya satu sisi yang sama.
            // Lebih baik satu sisi kosong dan terlihat kosong di detail view.
            let live: VisionInput? = camera.latestFrame.map { VisionInput.pixelBuffer($0) }
            let sideAInput = photo1.map { VisionInput.pixelBuffer($0) } ?? live
            let sideBInput = photo2.map { VisionInput.pixelBuffer($0) } ?? live

            if photo1 == nil { print("⚠️ Foto sisi A memakai frame live — capture 1 tidak ada") }
            if photo2 == nil { print("⚠️ Foto sisi B memakai frame live — capture 2 tidak ada") }

            // SISI B ("bawah") sering gagal diisolasi karena mangga jauh/kecil di
            // mangkuk. Kalau gagal, jangan pakai frame penuh — crop tetap ke area
            // mangkuk supaya framing-nya tetap mangga, bukan seisi rig.
            if let sideAInput { imageA = await pipeline.rejectPhoto(sideAInput) }
            if let sideBInput {
                imageB = await pipeline.rejectPhoto(sideBInput, fallbackCrop: Self.bowlFallbackCrop)
            }

            print("🖼️ Reject photos — A: \(imageA?.count ?? 0)B, B: \(imageB?.count ?? 0)B")

            if imageA == nil { print("⚠️ Foto reject sisi A gagal dibuat") }
            if imageB == nil { print("⚠️ Foto reject sisi B gagal dibuat") }
        }

        publish(
            .done,
            result: stationResult(from: evaluated, imageA: imageA, imageB: imageB)
        )
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
            
        case .loadCellOffline:
            loadCellReady = false
            print("❌ Load Cell OFFLINE")
            publish(.idle)
            
        case .servoReady:
            servoReady = true
            print("⚙️ Servo READY")
            publish(.idle)
            
        case .servoOffline:
            servoReady = false
            print("❌ Servo OFFLINE")
            publish(.idle)
            
        case .hardwareReady:
            loadCellReady = true
            servoReady = true

            print("✅ Hardware READY")
            print("⚖️ Load Cell READY")
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
