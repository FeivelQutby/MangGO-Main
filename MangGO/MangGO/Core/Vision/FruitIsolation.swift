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

    /// Potongan buah dari frame **mentah** (background tidak diratakan), dipotong
    /// ke `cropRect` yang sama dengan `image`. Ini yang disimpan sebagai foto
    /// dokumentasi mangga reject — operator ingin melihat buah apa adanya, bukan
    /// versi yang latarnya sudah diganti warna kulit.
    let rawCrop: CGImage

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
    /// Dipakai **hanya** untuk membuang deteksi yang jatuh di latar.
    ///
    /// Jangan dipakai mengukur luas: pengikisan memangkas beberapa piksel tepi,
    /// jadi luasnya sedikit lebih kecil dari siluet yang menghasilkan
    /// `areaRatio`. Untuk pengukuran, pakai `silhouette`.
    let mask: PixelMask

    /// Siluet buah **tanpa pengikisan**, koordinat frame penuh.
    ///
    /// Ini siluet yang menghasilkan `areaRatio`, jadi luas bintik harus diukur
    /// terhadap mask yang sama supaya pembilang dan penyebut `spotCoverage`
    /// benar-benar sebanding.
    let silhouette: PixelMask

    /// Berapa banyak instance latar-depan yang dilihat Vision, dihitung setelah
    /// pecahan siluet yang bersebelahan digabung. Lebih dari satu artinya ada
    /// objek lain yang ikut terangkat dan salah satu dibuang.
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

    /// Luas bintik terhadap **frame penuh**, diukur sebagai union kotak deteksi
    /// yang diiris dengan siluet buah. Sengaja memakai penyebut yang sama dengan
    /// `fruitAreaRatio` supaya keduanya bisa langsung dibagi tanpa konversi.
    var defectAreaRatio: Double

    var color: ColorProfile

    /// Deteksi yang dibuang karena tidak cukup tumpang tindih dengan siluet buah.
    var rejectedDetections: Int
}
