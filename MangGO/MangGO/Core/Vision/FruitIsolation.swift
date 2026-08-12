import Foundation
import CoreGraphics

/// Hasil memisahkan buah dari isi kotak lainnya.
///
/// Ada karena detektor bintik tidak tahu apa itu mangga: kabel, servo, dudukan
/// biru, dan mangga kedua di wadah atas semuanya bisa keluar sebagai `defect`.
/// Deteksi baru dijalankan setelah frame dipersempit ke satu buah.
struct FruitIsolation: @unchecked Sendable {
    /// Potongan buah yang latarnya sudah diratakan. Ini yang masuk ke detektor.
    let image: CGImage

    /// Posisi `image` di dalam frame penuh, koordinat Vision ternormalisasi
    /// (origin kiri-bawah). Dipakai memetakan bounding box hasil deteksi
    /// kembali ke koordinat frame penuh.
    let cropRect: CGRect

    /// Luas siluet buah dibagi luas frame penuh — nilai untuk
    /// `MangoSample.fruitAreaRatio`.
    let areaRatio: Double

    /// HSV median kulit buah, dihitung hanya dari piksel di dalam mask.
    let color: ColorProfile

    /// Siluet buah yang sudah dikikis, dalam koordinat frame penuh.
    /// Dipakai membuang deteksi yang jatuh di latar.
    let mask: PixelMask

    /// Berapa banyak instance latar-depan yang dilihat Vision. Lebih dari satu
    /// artinya ada objek lain yang ikut terangkat dan salah satu dibuang.
    let candidateCount: Int
}

/// Memisahkan satu buah dari latar sebelum tahap deteksi bintik.
protocol FruitIsolating: Sendable {
    func isolate(_ input: VisionInput) async throws -> FruitIsolation
}

/// Hasil satu siklus analisis: bintik yang sudah difilter plus metrik yang
/// ikut jatuh gratis dari mask.
struct DefectAnalysis: Sendable {
    var defects: [DefectObservation]
    var fruitAreaRatio: Double
    var color: ColorProfile

    /// Deteksi yang dibuang karena tidak cukup tumpang tindih dengan siluet buah.
    var rejectedDetections: Int
}
