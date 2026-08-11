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

    var color: ColorProfile?
    var dimensions: Dimensions?
    var mass: Grams?
}

extension MangoSample {
    /// Luas bintik relatif terhadap permukaan buah, bukan terhadap frame.
    var spotCoverage: Percentage? {
        guard let fruitAreaRatio, fruitAreaRatio > 0 else { return nil }
        let defectArea = defects.reduce(0) { $0 + $1.frameAreaRatio }
        return min(defectArea / fruitAreaRatio, 1) * 100
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
