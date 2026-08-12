import Foundation
import CoreGraphics

/// Urutan tetap satu siklus analisis: isolasi buah → deteksi bintik di potongan
/// buah → buang deteksi yang jatuh di latar → petakan kembali ke koordinat frame.
///
/// Tahap pemetaan balik itu bukan kosmetik. `MangoSample.spotCoverage` membagi
/// luas kotak deteksi dengan `fruitAreaRatio`, dan keduanya harus diukur pada
/// penyebut yang sama, yaitu frame penuh. Kalau bounding box dibiarkan relatif
/// terhadap potongan, persentase bintik jadi ikut membesar sesuai seberapa dekat
/// crop-nya — dan grade berubah hanya karena jarak kamera.
actor DefectPipeline {
    private let isolator: any FruitIsolating
    private let detector: any DefectDetecting
    private let minMaskOverlap: Double

    init(
        isolator: any FruitIsolating,
        detector: any DefectDetecting,
        minMaskOverlap: Double = 0.35
    ) {
        self.isolator = isolator
        self.detector = detector
        self.minMaskOverlap = minMaskOverlap
    }

    func analyze(_ input: VisionInput) async throws -> DefectAnalysis {
        let isolation = try await isolator.isolate(input)
        let raw = try await detector.detect(in: .image(isolation.image))

        var kept: [DefectObservation] = []
        var rejected = 0

        for observation in raw {
            var mapped = observation
            mapped.boundingBox = Self.projecting(
                observation.boundingBox,
                into: isolation.cropRect
            )

            guard isolation.mask.coverage(in: mapped.boundingBox) >= minMaskOverlap else {
                rejected += 1
                continue
            }
            kept.append(mapped)
        }

        return DefectAnalysis(
            defects: kept,
            fruitAreaRatio: isolation.areaRatio,
            color: isolation.color,
            rejectedDetections: rejected
        )
    }

    /// Kotak ternormalisasi terhadap potongan → ternormalisasi terhadap frame
    /// penuh. Keduanya koordinat Vision (origin kiri-bawah), jadi hanya perlu
    /// penskalaan dan pergeseran, tanpa pembalikan sumbu.
    static func projecting(_ box: CGRect, into crop: CGRect) -> CGRect {
        CGRect(
            x: crop.minX + box.minX * crop.width,
            y: crop.minY + box.minY * crop.height,
            width: box.width * crop.width,
            height: box.height * crop.height
        )
    }
}
