import Foundation
import CoreGraphics
import CoreVideo

enum VisionInput: @unchecked Sendable {
    case pixelBuffer(CVPixelBuffer)
    case image(CGImage)

    /// Tidak ada gambar. Hanya diterima implementasi mock untuk Preview dan
    /// Simulator yang tidak punya kamera.
    case unavailable
}

enum VisionError: LocalizedError {
    case modelUnavailable
    case noImage
    case inferenceFailed(Error)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Model Core ML belum tersedia."
        case .noImage:
            return "Tidak ada gambar untuk dianalisis."
        case .inferenceFailed(let error):
            return "Inferensi gagal: \(error.localizedDescription)"
        }
    }
}

protocol DefectDetecting: Sendable {
    func detect(in input: VisionInput) async throws -> [DefectObservation]
}

/// Memisahkan siluet buah dari latar. Dibutuhkan karena persentase bintik
/// diukur terhadap permukaan buah, bukan terhadap seluruh frame.
protocol FruitSegmenting: Sendable {
    func fruitAreaRatio(in input: VisionInput) async throws -> Double
}
