import Foundation
import CoreGraphics
import CoreVideo

/// Bitmap satu byte per piksel. Nilai `0` = latar, `> 0` = bagian objek.
///
/// Baris `0` ada di **atas** gambar, sedangkan Vision memakai origin kiri-bawah.
/// Semua API di sini yang menerima atau mengembalikan `CGRect` ternormalisasi
/// memakai konvensi Vision, konversinya dilakukan di dalam.
struct PixelMask: Sendable {
    let width: Int
    let height: Int
    private(set) var values: [UInt8]

    init(width: Int, height: Int, values: [UInt8]) {
        precondition(values.count == width * height, "Ukuran buffer tidak cocok.")
        self.width = width
        self.height = height
        self.values = values
    }

    /// Mask yang seluruhnya terisi. Dipakai jalur mock supaya tidak ada deteksi
    /// yang terbuang saat tidak ada segmentasi nyata.
    static func filled(width: Int, height: Int) -> PixelMask {
        PixelMask(width: width, height: height, values: [UInt8](repeating: 255, count: width * height))
    }

    // MARK: - Membaca instance mask dari Vision

    /// `VNInstanceMaskObservation.instanceMask` menyimpan indeks instance per
    /// piksel (`0` = latar). Formatnya normalnya `OneComponent8`; varian float
    /// ikut ditangani supaya tidak pecah kalau Vision mengubah backing format.
    init?(instanceMaskBuffer buffer: CVPixelBuffer) {
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        guard width > 0, height > 0 else { return nil }

        guard CVPixelBufferLockBaseAddress(buffer, .readOnly) == kCVReturnSuccess,
              let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

        let stride = CVPixelBufferGetBytesPerRow(buffer)
        var output = [UInt8](repeating: 0, count: width * height)

        switch CVPixelBufferGetPixelFormatType(buffer) {
        case kCVPixelFormatType_OneComponent8:
            for y in 0..<height {
                let row = base.advanced(by: y * stride).assumingMemoryBound(to: UInt8.self)
                for x in 0..<width { output[y * width + x] = row[x] }
            }
        case kCVPixelFormatType_OneComponent32Float:
            for y in 0..<height {
                let row = base.advanced(by: y * stride).assumingMemoryBound(to: Float.self)
                for x in 0..<width {
                    output[y * width + x] = UInt8(clamping: Int(row[x].rounded()))
                }
            }
        default:
            return nil
        }

        self.init(width: width, height: height, values: output)
    }

    // MARK: - Turunan

    var pixelCount: Int { width * height }

    var filledCount: Int {
        values.reduce(into: 0) { total, value in
            if value > 0 { total += 1 }
        }
    }

    /// Piksel yang indeksnya `index` dijadikan 255, sisanya 0.
    func isolating(instance index: UInt8) -> PixelMask {
        PixelMask(
            width: width,
            height: height,
            values: values.map { $0 == index ? 255 : 0 }
        )
    }

    /// Kotak pembatas piksel terisi, dalam koordinat Vision ternormalisasi
    /// (origin kiri-bawah). `nil` kalau mask kosong.
    var normalizedBounds: CGRect? {
        var minX = width, maxX = -1, minRow = height, maxRow = -1

        for row in 0..<height {
            let offset = row * width
            for x in 0..<width where values[offset + x] > 0 {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if row < minRow { minRow = row }
                if row > maxRow { maxRow = row }
            }
        }

        guard maxX >= minX, maxRow >= minRow else { return nil }

        let w = CGFloat(width), h = CGFloat(height)
        return CGRect(
            x: CGFloat(minX) / w,
            y: 1 - CGFloat(maxRow + 1) / h,
            width: CGFloat(maxX - minX + 1) / w,
            height: CGFloat(maxRow - minRow + 1) / h
        )
    }

    /// Titik berat piksel terisi, koordinat Vision ternormalisasi.
    var normalizedCentroid: CGPoint? {
        var sumX = 0, sumRow = 0, count = 0
        for row in 0..<height {
            let offset = row * width
            for x in 0..<width where values[offset + x] > 0 {
                sumX += x
                sumRow += row
                count += 1
            }
        }
        guard count > 0 else { return nil }
        let cx = CGFloat(sumX) / CGFloat(count) / CGFloat(width)
        let cy = CGFloat(sumRow) / CGFloat(count) / CGFloat(height)
        return CGPoint(x: cx, y: 1 - cy)
    }

    /// Fraksi piksel terisi di dalam `rect` (koordinat Vision ternormalisasi).
    ///
    /// Dipakai membuang deteksi yang jatuh di latar: kotak yang tumpang tindih
    /// dengan siluet buah di bawah ambang dianggap noise, bukan bintik.
    func coverage(in rect: CGRect) -> Double {
        guard let region = pixelRegion(for: rect) else { return 0 }

        var filled = 0, total = 0
        for row in region.rows {
            let offset = row * width
            for x in region.columns {
                total += 1
                if values[offset + x] > 0 { filled += 1 }
            }
        }
        return total > 0 ? Double(filled) / Double(total) : 0
    }

    /// Mengikis tepi mask `radius` piksel dengan min-filter 3x3 berulang.
    ///
    /// Tepi siluet selalu mengandung piksel latar; tanpa dikikis, deteksi yang
    /// menempel di kontur buah bisa lolos filter hanya karena menyentuh mask.
    func eroded(by radius: Int) -> PixelMask {
        guard radius > 0, width > 2, height > 2 else { return self }

        var current = values
        for _ in 0..<radius {
            var next = current
            for row in 0..<height {
                for x in 0..<width {
                    let index = row * width + x
                    guard current[index] > 0 else { continue }

                    if row == 0 || row == height - 1 || x == 0 || x == width - 1 {
                        next[index] = 0
                        continue
                    }

                    let above = index - width, below = index + width
                    let touchesBackground =
                        current[above - 1] == 0 || current[above] == 0 || current[above + 1] == 0
                        || current[index - 1] == 0 || current[index + 1] == 0
                        || current[below - 1] == 0 || current[below] == 0 || current[below + 1] == 0

                    if touchesBackground { next[index] = 0 }
                }
            }
            current = next
        }
        return PixelMask(width: width, height: height, values: current)
    }

    /// Mask sebagai gambar grayscale supaya bisa dipakai Core Image.
    func makeCGImage() -> CGImage? {
        guard let provider = CGDataProvider(data: Data(values) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    // MARK: - Internal

    struct Region: Sendable {
        let columns: Range<Int>
        let rows: Range<Int>
    }

    /// Konversi rect Vision (y ke atas) ke rentang baris/kolom piksel (y ke bawah).
    func pixelRegion(for rect: CGRect) -> Region? {
        guard width > 0, height > 0, rect.width > 0, rect.height > 0 else { return nil }

        let minX = clampIndex(Int((rect.minX * CGFloat(width)).rounded(.down)), limit: width)
        let maxX = clampIndex(Int((rect.maxX * CGFloat(width)).rounded(.up)), limit: width)
        let minRow = clampIndex(Int(((1 - rect.maxY) * CGFloat(height)).rounded(.down)), limit: height)
        let maxRow = clampIndex(Int(((1 - rect.minY) * CGFloat(height)).rounded(.up)), limit: height)

        let columns = minX..<max(minX + 1, maxX)
        let rows = minRow..<max(minRow + 1, maxRow)
        guard columns.upperBound <= width, rows.upperBound <= height else { return nil }
        return Region(columns: columns, rows: rows)
    }

    private func clampIndex(_ value: Int, limit: Int) -> Int {
        min(max(value, 0), limit)
    }
}
