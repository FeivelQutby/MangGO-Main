import Foundation
import AVFoundation

/// Menyediakan live preview dan frame terakhir dari kamera belakang.
///
/// Frame tidak di-push ke pemanggil. Grading berjalan per-buah, bukan per-frame,
/// jadi konsumen cukup membaca `latestFrame` saat menekan tombol analisis.
final class CameraSession: NSObject, @unchecked Sendable {
    enum Failure: LocalizedError {
        case cameraUnavailable
        case inputRejected
        case outputRejected

        var errorDescription: String? {
            switch self {
            case .cameraUnavailable: return "Kamera tidak tersedia."
            case .inputRejected: return "Input kamera ditolak."
            case .outputRejected: return "Output kamera ditolak."
            }
        }
    }

    let session = AVCaptureSession()

    private let queue = DispatchQueue(label: "com.kiki.MangGO.camera")
    private let output = AVCaptureVideoDataOutput()
    private let lock = NSLock()
    private var storedFrame: CVPixelBuffer?
    private var isConfigured = false

    var latestFrame: CVPixelBuffer? {
        lock.withLock { storedFrame }
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

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .hd1920x1080

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw Failure.cameraUnavailable
        }

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

        isConfigured = true
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
