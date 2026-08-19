import Foundation

/// Fakta hasil pengukuran satu buah. Keputusan mutu ada di `GradeResult`.
///
/// Field pengukuran optional karena diisi bertahap: scan sisi 1 → flip →
/// timbang → scan sisi 2.
struct MangoSample: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var capturedAt = Date.now

    var defects: [DefectObservation] = []

    /// Luas siluet buah relatif terhadap frame, dari segmentasi.
    var fruitAreaRatio: Double?

    /// Luas bintik relatif terhadap frame, hasil pengukuran piksel di
    /// `DefectPipeline`: union kotak deteksi yang diiris siluet buah.
    ///
    /// `nil` berarti **belum diukur**, bukan "tidak ada bintik" — dan itu
    /// membuat `spotCoverage` ikut `nil`, sehingga kriteria defek dilewati sama
    /// seperti berat yang belum masuk. Sengaja begitu: pembacaan yang tidak
    /// dipercaya tidak boleh dipakai menolak buah.
    var defectAreaRatio: Double?

    var color: ColorProfile?
    var dimensions: Dimensions?
    var mass: Grams?
}

extension MangoSample {
    /// Luas bintik relatif terhadap permukaan buah, bukan terhadap frame,
    /// dibatasi 100%.
    ///
    /// Dulu pembilangnya `Σ luas kotak deteksi`. Itu menghitung kotak yang
    /// bertumpuk berkali-kali dan ikut menghitung bagian kotak yang jatuh di
    /// latar, jadi angkanya bisa jauh melebihi luas buah — sementara batas
    /// `min(…, 1)` menyembunyikan seberapa jauh melesetnya. Sekarang
    /// pembilangnya luas piksel yang benar-benar terukur di dalam siluet.
    var spotCoverage: Percentage? {
        guard let ratio = rawSpotCoverage else { return nil }
        return min(ratio, 100)
    }

    /// `spotCoverage` tanpa dibatasi 100%.
    ///
    /// Nilai di atas 100% mustahil secara fisik — luas bintik tidak bisa
    /// melebihi luas buah — jadi ini dipakai sebagai alarm bahwa yang rusak
    /// pengukurannya, bukan buahnya. Angka yang sudah dibatasi tidak bisa
    /// membedakan 100% dari 400%.
    var rawSpotCoverage: Percentage? {
        guard let fruitAreaRatio, fruitAreaRatio > 0, let defectAreaRatio else { return nil }
        return defectAreaRatio / fruitAreaRatio * 100
    }

    var volume: CubicCentimeters? {
        dimensions?.volume
    }

    var density: Double? {
        guard let mass, let volume, volume > 0 else { return nil }
        return mass / volume
    }

    var isComplete: Bool {
        fruitAreaRatio != nil && color != nil && dimensions != nil && mass != nil
    }
}
