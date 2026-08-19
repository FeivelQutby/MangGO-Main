import Foundation
import CoreGraphics

struct DefectObservation: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()

    /// Ternormalisasi 0...1 dalam koordinat Vision (origin kiri-bawah).
    var boundingBox: CGRect
    var confidence: Float
    var label = "defect"

    /// Luas kotak relatif terhadap luas frame.
    ///
    /// JANGAN dijumlahkan untuk mengukur luas bintik. Kotak yang bertumpuk akan
    /// terhitung berkali-kali, dan bagian kotak yang menjulur ke latar ikut
    /// terhitung sebagai bintik di kulit buah — dua hal yang dulu membuat
    /// `spotCoverage` melebihi 100% dan menolak buah yang bagus. Pengukuran
    /// luas yang benar ada di `PixelMask.filledPixelCount(coveredByAnyOf:)`,
    /// yang meng-union kotak lalu mengirisnya dengan siluet buah.
    ///
    /// Yang tersisa untuk properti ini: ukuran satu kotak, misalnya untuk
    /// menyaring deteksi yang terlalu besar atau untuk overlay debug.
    var frameAreaRatio: Double {
        Double(boundingBox.width * boundingBox.height)
    }
}
