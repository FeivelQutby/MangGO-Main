import Foundation
import Vision
import CoreImage
import CoreGraphics
import CoreVideo

/// Memisahkan buah dari latar dengan `VNGenerateForegroundInstanceMaskRequest`.
///
/// Dipilih daripada model deteksi mangga terpisah karena tiga hal: tidak
/// menambah model ke bundle, mask-nya per-piksel bukan kotak, dan siluet yang
/// dihasilkan sekaligus menjadi penyebut `spotCoverage` — yang sebelumnya masih
/// angka mati di `MockFruitSegmenter`.
///
/// Yang API ini **tidak** tahu adalah kelas objek. Vision hanya mengangkat
/// "subjek latar-depan", jadi dudukan biru atau tangan yang memegang buah juga
/// bisa terangkat. Pemilihan instance di sini yang memutuskan mana mangga:
/// luas masuk rentang, titik berat di dalam region of interest, dan mayoritas
/// pikselnya berwarna seperti kulit mangga.
///
/// Actor karena `CIContext` dan model Vision tidak dijamin thread-safe.
actor VisionFruitIsolator: FruitIsolating, FruitSegmenting {

    struct Options: Sendable {
        /// Area frame yang boleh ditempati titik berat buah, koordinat Vision
        /// ternormalisasi (origin kiri-bawah).
        ///
        /// SETEL INI begitu posisi buah di rig diukur — ini cara termurah
        /// membuang mangga di wadah atas, kabel, dan dudukan dari pertimbangan,
        /// jauh lebih murah daripada mengetatkan ambang warna. Dibiarkan seluruh
        /// frame karena geometrinya hanya bisa diukur dari perangkat sungguhan:
        /// isi dengan kotak tempat buah benar-benar muncul, jangan menebak —
        /// angka tebakan persis yang membuat `bowlFallbackCrop` di
        /// `CaptureViewModel` berakhir memotret sekrup.
        var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)

        /// Luas siluet relatif frame yang dianggap masuk akal untuk satu buah.
        ///
        /// Batas bawah dinaikkan 0.03 → 0.05, dan alasannya bukan sekadar ingin
        /// lebih ketat: `MangoSample.spotCoverage` MEMBAGI dengan angka ini,
        /// jadi siluet 3% membuat luas bintik sekecil apa pun tampak besar.
        /// Sejak pecahan siluet digabung di `merging(_:bitmap:)`, siluet sekecil
        /// itu hampir pasti bukan buah utuh — menolaknya di sini lebih jujur
        /// daripada melaporkan persentase yang meledak.
        var areaRatioRange: ClosedRange<Double> = 0.05...0.95

        /// Jarak toleransi (fraksi sisi frame) saat memutuskan dua pecahan
        /// siluet bersebelahan dan layak digabung. `0` berarti kotaknya harus
        /// benar-benar bersinggungan.
        var instanceMergeTolerance: Double = 0.02

        /// Fraksi minimum piksel yang harus berwarna seperti kulit mangga.
        /// Dikembalikan ke 0.5 (dari 0.4): kabel jumper oranye/kuning + kardus
        /// cokelat di dasar box "berwarna mangga" buat Vision, jadi ambang yang
        /// terlalu longgar membuat gerombolan itu lolos & malah kepilih.
        var minFruitLikeness: Double = 0.5

        /// Margin di sekitar siluet sebelum dipotong, relatif sisi terpanjang.
        var cropPadding: Double = 0.06

        /// Potong persegi. `CoreMLDefectDetector` memakai `.scaleFill`, jadi
        /// crop non-persegi akan diregangkan dan mengubah bentuk bintik.
        var squareCrop = true

        /// Berapa piksel tepi mask dikikis sebelum dipakai memfilter deteksi.
        var maskErosion = 2

        /// Rentang hue kulit mangga dalam derajat: hijau → kuning → merah blush.
        /// Biru (dudukan, sekitar 200°) dan abu tak bersaturasi jatuh di luar.
        var fruitHueRanges: [ClosedRange<Double>] = [0...115, 330...360]
        var blushHueRanges: [ClosedRange<Double>] = [0...25, 335...360]
        /// Dikembalikan ke 0.16 (dari 0.12): ambang saturasi yang terlalu rendah
        /// membuat kardus/breadboard cokelat pudar ikut terhitung sebagai kulit
        /// buah, sehingga gerombolan latar bisa menang jadi "buah".
        var minSaturation: Double = 0.16
        var minBlushSaturation: Double = 0.25

        /// Orientasi buffer kamera belakang saat perangkat portrait.
        var bufferOrientation: CGImagePropertyOrientation = .right
    }

    private let options: Options
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    init(options: Options = Options()) {
        self.options = options
    }

    // MARK: - FruitIsolating

    func isolate(_ input: VisionInput) async throws -> FruitIsolation {
        let source = try uprightImage(from: input)
        let handler = VNImageRequestHandler(cgImage: source, orientation: .up)

        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
        } catch {
            throw VisionError.inferenceFailed(error)
        }

        guard let observation = request.results?.first,
              !observation.allInstances.isEmpty,
              let indexMask = PixelMask(instanceMaskBuffer: observation.instanceMask) else {
            throw VisionError.fruitNotFound
        }

        guard let bitmap = RGBBitmap(image: source, width: indexMask.width, height: indexMask.height) else {
            throw VisionError.unsupportedImage
        }

        let instances = observation.allInstances.compactMap { index -> PixelMask? in
            guard index > 0, index <= Int(UInt8.max) else { return nil }
            return indexMask.isolating(instance: UInt8(index))
        }

        let candidates = merging(
            instances.compactMap { evaluate(mask: $0, bitmap: bitmap) },
            bitmap: bitmap
        )

        // Instance terbesar yang lolos, bukan yang paling percaya diri: buah yang
        // sedang di-scan selalu paling dekat kamera, jadi mangga di wadah atas
        // kalah luas dengan sendirinya.
        let plausible = candidates.filter({ self.isPlausible($0) })
        guard let chosen = plausible.max(by: { $0.areaRatio < $1.areaRatio }) else {
            throw VisionError.fruitNotFound
        }

        let cropRect = makeCropRect(around: chosen.bounds, imageWidth: source.width, imageHeight: source.height)
        let cropped = try crop(source, to: cropRect, mask: chosen.mask, fill: chosen.medianColor)
        let rawCropped = try cropRaw(source, to: cropRect)

        return FruitIsolation(
            image: cropped,
            rawCrop: rawCropped,
            cropRect: cropRect,
            areaRatio: chosen.areaRatio,
            color: chosen.colorProfile,
            mask: chosen.mask.eroded(by: options.maskErosion),
            silhouette: chosen.mask,
            candidateCount: candidates.count
        )
    }

    // MARK: - FruitSegmenting

    func fruitAreaRatio(in input: VisionInput) async throws -> Double {
        try await isolate(input).areaRatio
    }

    // MARK: - Pemilihan instance

    private struct Candidate: Sendable {
        let mask: PixelMask
        let bounds: CGRect
        let centroid: CGPoint
        let areaRatio: Double
        let fruitLikeness: Double
        let medianColor: (r: Double, g: Double, b: Double)
        let colorProfile: ColorProfile
    }

    /// Menyatukan pecahan siluet yang sebenarnya satu buah.
    ///
    /// Vision kadang mengangkat satu mangga sebagai beberapa instance — bagian
    /// yang kena cahaya dan bagian yang di bayangan terpisah, atau tangkai
    /// terlepas dari badannya. Kalau itu terjadi, memilih "instance terluas"
    /// berarti memilih SEPARUH buah. Akibatnya berantai: `areaRatio` jadi
    /// separuh, dan karena `spotCoverage` membaginya, persentase bintik langsung
    /// berlipat tanpa ada yang berubah pada buahnya. Inilah kenapa satu mangga
    /// yang sama bisa lolos di satu pengambilan dan ditolak di pengambilan
    /// berikutnya hanya karena pencahayaan bergeser sedikit.
    ///
    /// Syarat gabung sengaja ketat: hanya kandidat yang **masing-masing** sudah
    /// berwarna kulit buah dan kotaknya bersinggungan. Dudukan biru dan kabel
    /// tidak lolos syarat warna, jadi tidak ikut tertarik masuk — kalau ikut,
    /// mask-nya justru membengkak dan buahnya malah gagal dikenali.
    private func merging(_ candidates: [Candidate], bitmap: RGBBitmap) -> [Candidate] {
        let fruitLike = candidates.filter { $0.fruitLikeness >= options.minFruitLikeness }
        guard fruitLike.count > 1 else { return candidates }

        // Digabung berulang sampai stabil, bukan sekali jalan: A bisa
        // bersinggungan dengan C dan B juga dengan C tanpa A menyentuh B, dan
        // ketiganya tetap harus berakhir di satu grup.
        var groups: [[Candidate]] = fruitLike.map { [$0] }
        var didMerge = true

        while didMerge {
            didMerge = false
            merge: for i in groups.indices {
                for j in groups.indices where j > i {
                    let adjacent = groups[i].contains { left in
                        groups[j].contains { touching(left.bounds, $0.bounds) }
                    }
                    guard adjacent else { continue }

                    groups[i].append(contentsOf: groups[j])
                    groups.remove(at: j)
                    didMerge = true
                    break merge
                }
            }
        }

        // Kandidat yang warnanya bukan kulit buah dibiarkan lewat apa adanya.
        // Mereka akan gugur sendiri di `isPlausible`, tapi tetap ikut terhitung
        // di `candidateCount` sebagai penanda "ada objek lain di frame".
        let others = candidates.filter { $0.fruitLikeness < options.minFruitLikeness }

        let merged = groups.compactMap { group -> Candidate? in
            guard let first = group.first else { return nil }
            guard group.count > 1 else { return first }

            // Warna dan luas dihitung ulang pada mask gabungan — bukan diambil
            // dari pecahan terbesar — supaya median HSV mewakili seluruh buah.
            let union = group.dropFirst().reduce(first.mask) { $0.union($1.mask) }
            return evaluate(mask: union, bitmap: bitmap) ?? first
        }

        return merged + others
    }

    /// Dua kotak dianggap bersebelahan kalau bersinggungan setelah masing-masing
    /// dilebarkan `instanceMergeTolerance`. Toleransi ini menutup celah tipis
    /// antara dua pecahan mask yang dipisahkan garis bayangan.
    private func touching(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        let tolerance = CGFloat(options.instanceMergeTolerance)
        return lhs.insetBy(dx: -tolerance, dy: -tolerance)
            .intersects(rhs.insetBy(dx: -tolerance, dy: -tolerance))
    }

    private func evaluate(mask: PixelMask, bitmap: RGBBitmap) -> Candidate? {
        guard let bounds = mask.normalizedBounds,
              let centroid = mask.normalizedCentroid else { return nil }

        var reds: [Double] = [], greens: [Double] = [], blues: [Double] = []
        var hues: [Double] = [], saturations: [Double] = [], values: [Double] = []
        var fruitLike = 0, blushLike = 0, total = 0

        for pixel in 0..<mask.pixelCount where mask.values[pixel] > 0 {
            let rgb = bitmap.color(at: pixel)
            let hsv = HSV(r: rgb.r, g: rgb.g, b: rgb.b)
            total += 1
            reds.append(rgb.r); greens.append(rgb.g); blues.append(rgb.b)
            // Hue dipetakan ke negatif di ujung merah supaya median tidak
            // terlempar ke tengah spektrum saat blush membungkus 0°.
            hues.append(hsv.hue > 300 ? hsv.hue - 360 : hsv.hue)
            saturations.append(hsv.saturation)
            values.append(hsv.value)

            if hsv.saturation >= options.minSaturation,
               options.fruitHueRanges.contains(where: { $0.contains(hsv.hue) }) {
                fruitLike += 1
            }
            if hsv.saturation >= options.minBlushSaturation,
               options.blushHueRanges.contains(where: { $0.contains(hsv.hue) }) {
                blushLike += 1
            }
        }

        guard total > 0 else { return nil }

        let medianHue = median(hues)
        let profile = ColorProfile(
            hue: (medianHue < 0 ? medianHue + 360 : medianHue) / 2,
            saturation: median(saturations) * 255,
            brightness: median(values) * 255,
            blushCoverage: Double(blushLike) / Double(total) * 100
        )

        return Candidate(
            mask: mask,
            bounds: bounds,
            centroid: centroid,
            areaRatio: Double(total) / Double(mask.pixelCount),
            fruitLikeness: Double(fruitLike) / Double(total),
            medianColor: (median(reds), median(greens), median(blues)),
            colorProfile: profile
        )
    }

    private func isPlausible(_ candidate: Candidate) -> Bool {
        options.areaRatioRange.contains(candidate.areaRatio)
            && candidate.fruitLikeness >= options.minFruitLikeness
            && options.regionOfInterest.contains(candidate.centroid)
    }

    private func median(_ samples: [Double]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sorted = samples.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[middle - 1] + sorted[middle]) / 2
            : sorted[middle]
    }

    // MARK: - Crop

    /// Kotak crop dalam koordinat Vision ternormalisasi. Persegi dihitung di
    /// ruang piksel, bukan ruang ternormalisasi, supaya benar-benar persegi.
    private func makeCropRect(around bounds: CGRect, imageWidth: Int, imageHeight: Int) -> CGRect {
        let width = CGFloat(imageWidth), height = CGFloat(imageHeight)
        var rect = CGRect(
            x: bounds.minX * width,
            y: bounds.minY * height,
            width: bounds.width * width,
            height: bounds.height * height
        )

        let padding = CGFloat(options.cropPadding) * max(rect.width, rect.height)
        rect = rect.insetBy(dx: -padding, dy: -padding)

        if options.squareCrop {
            let side = min(max(rect.width, rect.height), min(width, height))
            rect = CGRect(
                x: rect.midX - side / 2,
                y: rect.midY - side / 2,
                width: side,
                height: side
            )
        }

        rect.origin.x = min(max(rect.origin.x, 0), max(0, width - rect.width))
        rect.origin.y = min(max(rect.origin.y, 0), max(0, height - rect.height))
        rect.size.width = min(rect.width, width)
        rect.size.height = min(rect.height, height)

        return CGRect(
            x: rect.minX / width,
            y: rect.minY / height,
            width: rect.width / width,
            height: rect.height / height
        )
    }

    /// Latar diisi warna median kulit buah, bukan hitam. Bidang rata yang
    /// warnanya sama dengan buah tidak menciptakan tepi kontras baru di kontur —
    /// tepi buatan itu justru sumber deteksi bintik palsu.
    private func crop(
        _ source: CGImage,
        to rect: CGRect,
        mask: PixelMask,
        fill: (r: Double, g: Double, b: Double)
    ) throws -> CGImage {
        let image = CIImage(cgImage: source)
        let extent = image.extent

        guard let maskImage = mask.makeCGImage() else { throw VisionError.unsupportedImage }
        let scaledMask = CIImage(cgImage: maskImage).transformed(
            by: CGAffineTransform(
                scaleX: extent.width / CGFloat(mask.width),
                y: extent.height / CGFloat(mask.height)
            )
        )

        let background = CIImage(color: CIColor(red: fill.r, green: fill.g, blue: fill.b))
            .cropped(to: extent)

        let blended = image.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: background,
            kCIInputMaskImageKey: scaledMask
        ])

        let pixelRect = CGRect(
            x: rect.minX * extent.width,
            y: rect.minY * extent.height,
            width: rect.width * extent.width,
            height: rect.height * extent.height
        ).integral

        let cropped = blended.cropped(to: pixelRect)
        guard let output = context.createCGImage(cropped, from: cropped.extent) else {
            throw VisionError.unsupportedImage
        }
        return output
    }

    /// Potong `cropRect` yang sama tapi dari frame tegak **mentah**, tanpa
    /// meratakan latar. Dipakai untuk foto dokumentasi mangga reject. `source`
    /// sudah tegak dan `rect` koordinat Vision (origin kiri-bawah), sama seperti
    /// `crop(_:to:mask:fill:)`, jadi hasilnya sejajar dengan `image`.
    private func cropRaw(_ source: CGImage, to rect: CGRect) throws -> CGImage {
        let image = CIImage(cgImage: source)
        let extent = image.extent

        let pixelRect = CGRect(
            x: rect.minX * extent.width,
            y: rect.minY * extent.height,
            width: rect.width * extent.width,
            height: rect.height * extent.height
        ).integral

        let cropped = image.cropped(to: pixelRect)
        guard let output = context.createCGImage(cropped, from: cropped.extent) else {
            throw VisionError.unsupportedImage
        }
        return output
    }

    // MARK: - Normalisasi input

    /// Semua tahap berikutnya bekerja di satu `CGImage` tegak. Rotasi
    /// diselesaikan sekali di sini supaya tidak ada lagi flag orientasi yang
    /// harus dijaga konsisten antara mask, crop, dan detektor.
    private func uprightImage(from input: VisionInput) throws -> CGImage {
        switch input {
        case .image(let image):
            return image
        case .pixelBuffer(let buffer):
            let oriented = CIImage(cvPixelBuffer: buffer).oriented(options.bufferOrientation)
            guard let image = context.createCGImage(oriented, from: oriented.extent) else {
                throw VisionError.unsupportedImage
            }
            return image
        case .unavailable:
            throw VisionError.noImage
        }
    }
}

