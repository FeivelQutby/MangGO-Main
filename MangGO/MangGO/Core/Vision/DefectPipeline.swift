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

        // Luas bintik diukur dengan menghitung piksel siluet yang tertutup kotak
        // deteksi, bukan dengan menjumlahkan luas kotaknya.
        //
        // Penjumlahan luas kotak salah dua kali: kotak yang bertumpuk dihitung
        // berulang, dan bagian kotak yang menjulur ke latar ikut terhitung
        // sebagai bintik di kulit buah. `minMaskOverlap` di atas cuma memutuskan
        // sebuah kotak dibuang atau tidak — begitu lolos, dulu seluruh luasnya
        // masuk. Gabungan keduanya bisa melaporkan luas bintik beberapa kali
        // lipat dari luas fisiknya, yang lalu menabrak ambang diskualifikasi 30%
        // di `GradingEngine` dan menolak buah yang sebenarnya bagus.
        let defectPixels = isolation.silhouette.filledPixelCount(
            coveredByAnyOf: kept.map(\.boundingBox)
        )

        return DefectAnalysis(
            defects: kept,
            fruitAreaRatio: isolation.areaRatio,
            defectAreaRatio: Double(defectPixels) / Double(isolation.silhouette.pixelCount),
            color: isolation.color,
            rejectedDetections: rejected
        )
    }

    /// Foto dokumentasi satu sisi mangga sebagai JPEG. Pertama coba potong kotak
    /// buah dari frame mentah (background apa adanya). Kalau buah tidak ketemu
    /// (mis. mangga jauh/kecil di mangkuk pada sisi "bawah"), jatuh ke
    /// `fallbackCrop` bila diberi — crop tetap ke area rig (mangkuk) — atau frame
    /// penuh kalau tidak. Encoding dilakukan di dalam actor ini sehingga
    /// `CGImage` tidak pernah menyeberang isolasi; yang keluar hanya `Data`.
    func rejectPhoto(_ input: VisionInput, fallbackCrop: CGRect? = nil) async -> Data? {
        if let crop = try? await isolator.isolate(input).rawCrop,
           let data = MangoImageEncoder.jpeg(from: crop) {
            return data
        }
        return MangoImageEncoder.jpeg(from: input, cropRect: fallbackCrop)
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
