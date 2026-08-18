import Foundation
import AVFoundation
import CoreGraphics
import CoreMedia

/// Menyediakan live preview dan frame terakhir dari kamera belakang.
///
/// Frame tidak di-push ke pemanggil. Grading berjalan per-buah, bukan per-frame,
/// jadi konsumen cukup membaca `latestFrame` saat menekan tombol analisis.
final class CameraSession: NSObject, @unchecked Sendable {
    enum Failure: LocalizedError {
        case cameraUnavailable
        case inputRejected
        case outputRejected
        case formatUnavailable(aspect: String)

        var errorDescription: String? {
            switch self {
            case .cameraUnavailable: return "Kamera tidak tersedia."
            case .inputRejected: return "Input kamera ditolak."
            case .outputRejected: return "Output kamera ditolak."
            case .formatUnavailable(let aspect):
                return "Kamera tidak punya format \(aspect)."
            }
        }
    }

    struct Configuration: Sendable {
        /// Rasio sensor yang diminta. `4:3` di ruang landscape — setelah frame
        /// diputar tegak, tampilannya jadi `3:4` portrait.
        var aspectWidth = 4
        var aspectHeight = 3

        /// Sisi panjang format yang diincar. 1920 cukup detail untuk bintik
        /// kecil tanpa membuat inferensi dan Core Image jadi berat.
        var preferredLongSide = 1920

        /// Skala tampilan seperti di app Kamera: `0.5` = ultra-wide, `1` = wide.
        var displayZoom: CGFloat = 1

        /// Koreksi distorsi barrel. Wajib kalau frame ini juga dipakai mengukur
        /// dimensi: tanpa ini, buah yang sama terbaca lebih besar di tepi frame
        /// daripada di tengah, dan kalibrasi px→mm tidak akan pernah konsisten.
        var correctsGeometricDistortion = true

        /// HDR memetakan ulang tonal per frame. Untuk ambang hue/saturasi/value
        /// yang absolut, itu berarti pembacaan warna ikut bergeser.
        var disablesVideoHDR = true
    }

    /// Apa yang benar-benar didapat setelah negosiasi dengan hardware.
    /// Diperiksa UI: kalau `isUltraWideActive` false padahal diminta 0.5x,
    /// perangkat ini tidak punya lensa ultra-wide.
    struct Capabilities: Sendable {
        var deviceName = ""
        var bufferSize = CGSize.zero
        var requestedDisplayZoom: CGFloat = 1
        var activeDisplayZoom: CGFloat = 1
        var isUltraWideActive = false
        var isDistortionCorrected = false

        /// Rasio lebar:tinggi frame setelah diputar tegak. Dipakai view untuk
        /// menyamakan kontainer preview dengan frame yang benar-benar dianalisis.
        var uprightAspectRatio: CGFloat {
            guard bufferSize.width > 0, bufferSize.height > 0 else { return 3.0 / 4.0 }
            return bufferSize.height / bufferSize.width
        }
    }

    let session = AVCaptureSession()
    let configuration: Configuration

    /// Orientasi buffer kamera belakang saat perangkat dipegang portrait.
    /// Nilai yang sama dipakai preview layer (`videoRotationAngle = 90`) dan
    /// Vision, jadi overlay dan hasil deteksi tidak pernah beda 90°.
    let bufferOrientation: CGImagePropertyOrientation = .right

    private let queue = DispatchQueue(label: "com.kiki.MangGO.camera")
    private let output = AVCaptureVideoDataOutput()
    private let lock = NSLock()
    private var storedFrame: CVPixelBuffer?
    private var isConfigured = false
    private var storedCapabilities = Capabilities()
    private var device: AVCaptureDevice?

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        super.init()
    }

    var latestFrame: CVPixelBuffer? {
        lock.withLock { storedFrame }
    }

    var capabilities: Capabilities {
        lock.withLock { storedCapabilities }
    }

    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    func start() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    try self.configureIfNeeded()
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func stop() {
        queue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    /// Membekukan exposure dan white balance pada nilai yang sedang aktif.
    ///
    /// Di light box pencahayaannya tetap, jadi auto-WB hanya menambah variasi:
    /// mangga yang sama bisa terbaca hue berbeda antar pengambilan. Panggil ini
    /// sekali setelah preview stabil, sebelum batch grading dimulai.
    func lockColorSettings() {
        queue.async {
            guard let device = self.device, (try? device.lockForConfiguration()) != nil else { return }
            defer { device.unlockForConfiguration() }

            if device.isWhiteBalanceModeSupported(.locked) {
                device.whiteBalanceMode = .locked
            }
            if device.isExposureModeSupported(.locked) {
                device.exposureMode = .locked
            }
        }
    }

    // MARK: - Konfigurasi

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // `inputPriority` karena format dipilih manual lewat `activeFormat`.
        // Preset apa pun akan menimpa pilihan itu.
        session.sessionPreset = .inputPriority

        let device = try selectDevice()
        self.device = device

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw Failure.inputRejected }
        session.addInput(input)

        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: queue)

        guard session.canAddOutput(output) else { throw Failure.outputRejected }
        session.addOutput(output)

        try configureDevice(device)
        isConfigured = true
    }

    /// Urutan pencarian dimulai dari virtual device. Virtual device yang
    /// mengandung ultra-wide memberi 0.5x sambil tetap punya autofocus dan
    /// perpindahan lensa otomatis; `builtInUltraWideCamera` mentah dipakai hanya
    /// kalau virtual device tidak menyediakan ultra-wide di format 4:3.
    private func selectDevice() throws -> AVCaptureDevice {
        var types: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera, .builtInDualWideCamera]
        if configuration.displayZoom < 1 {
            types.append(.builtInUltraWideCamera)
        }
        types.append(.builtInWideAngleCamera)

        for type in types {
            if let device = AVCaptureDevice.default(type, for: .video, position: .back) {
                return device
            }
        }
        throw Failure.cameraUnavailable
    }

    private func configureDevice(_ device: AVCaptureDevice) throws {
        let format = try selectFormat(for: device)

        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        device.activeFormat = format

        if configuration.disablesVideoHDR {
            if device.activeFormat.isVideoHDRSupported {
                device.automaticallyAdjustsVideoHDREnabled = false
                device.isVideoHDREnabled = false
            }
        }

        if configuration.correctsGeometricDistortion,
           device.isGeometricDistortionCorrectionSupported {
            device.isGeometricDistortionCorrectionEnabled = true
        }

        let base = baseZoomFactor(for: device)
        let requested = configuration.displayZoom * base
        device.videoZoomFactor = min(
            max(requested, device.minAvailableVideoZoomFactor),
            device.maxAvailableVideoZoomFactor
        )

        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        let activeZoom = device.videoZoomFactor / base

        lock.withLock {
            storedCapabilities = Capabilities(
                deviceName: device.localizedName,
                bufferSize: CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height)),
                requestedDisplayZoom: configuration.displayZoom,
                activeDisplayZoom: activeZoom,
                isUltraWideActive: activeZoom < 0.99,
                isDistortionCorrected: device.isGeometricDistortionCorrectionEnabled
            )
        }
    }

    /// Faktor `videoZoomFactor` yang setara dengan tampilan 1x.
    ///
    /// Untuk virtual device, `videoZoomFactor` 1.0 adalah lensa terlebar yang
    /// dikandungnya — di device yang punya ultra-wide itu tampilan 0.5x, dan
    /// titik pindah ke wide (nilai pertama `virtualDeviceSwitchOverVideoZoomFactors`,
    /// biasanya 2.0) adalah tampilan 1x. Untuk `builtInUltraWideCamera` mentah
    /// tidak ada switch-over, tapi hubungannya sama: 1x = faktor 2.0.
    private func baseZoomFactor(for device: AVCaptureDevice) -> CGFloat {
        if let switchOver = device.virtualDeviceSwitchOverVideoZoomFactors.first {
            return CGFloat(switchOver.doubleValue)
        }
        if device.deviceType == .builtInUltraWideCamera {
            return 2.0
        }
        return 1.0
    }

    private func selectFormat(for device: AVCaptureDevice) throws -> AVCaptureDevice.Format {
        let aspectWidth = configuration.aspectWidth
        let aspectHeight = configuration.aspectHeight

        let matching = device.formats.filter { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            guard dimensions.width > 0, dimensions.height > 0 else { return false }
            guard Int(dimensions.width) * aspectHeight == Int(dimensions.height) * aspectWidth else {
                return false
            }
            return format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= 30 }
        }

        guard !matching.isEmpty else {
            throw Failure.formatUnavailable(aspect: "\(aspectWidth):\(aspectHeight)")
        }

        // Format binned menggabungkan piksel sensor; detailnya hilang justru di
        // skala bintik kecil, jadi dihindari kalau ada alternatif resolusi sama.
        return matching.min { lhs, rhs in
            let lhsDimensions = CMVideoFormatDescriptionGetDimensions(lhs.formatDescription)
            let rhsDimensions = CMVideoFormatDescriptionGetDimensions(rhs.formatDescription)
            let lhsDistance = abs(Int(lhsDimensions.width) - configuration.preferredLongSide)
            let rhsDistance = abs(Int(rhsDimensions.width) - configuration.preferredLongSide)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            return !lhs.isVideoBinned && rhs.isVideoBinned
        } ?? matching[0]
    }
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lock.withLock { storedFrame = buffer }
    }
}
