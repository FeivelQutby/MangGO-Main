import Foundation
import CoreGraphics
import CoreImage
import CoreVideo
import ImageIO
import UniformTypeIdentifiers

/// Encode potongan mangga jadi JPEG kecil untuk dokumentasi reject.
///
/// Sengaja diperkecil dulu (sisi terpanjang dibatasi) supaya payload yang
/// menyeberang link lokal iPhone → iPad ringan, dan supaya UserDefaults/disk di
/// iPad tidak membengkak. Kualitas 0.6 sudah cukup untuk melihat bintik/warna.
enum MangoImageEncoder {

    /// CIContext dipakai ulang; membuatnya per panggilan mahal. Aman dipakai
    /// lintas thread untuk rendering.
    nonisolated(unsafe) private static let ciContext =
        CIContext(options: [.useSoftwareRenderer: false])

    /// JPEG dari `CGImage` yang sudah tegak.
    static func jpeg(
        from image: CGImage,
        maxDimension: CGFloat = 640,
        quality: CGFloat = 0.6
    ) -> Data? {
        let scaled = resized(image, maxDimension: maxDimension) ?? image

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }

        CGImageDestinationAddImage(destination, scaled, [
            kCGImageDestinationLossyCompressionQuality: quality
        ] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    /// JPEG dari `VisionInput`. Untuk `.pixelBuffer` orientasinya diselesaikan
    /// dengan orientasi buffer kamera belakang (`.right`) supaya hasilnya tegak,
    /// sama seperti jalur di `VisionFruitIsolator.uprightImage`.
    /// `cropRect` opsional dalam koordinat Vision ternormalisasi (origin
    /// kiri-bawah), sama seperti `cropRect` di isolator. Dipakai untuk memotong
    /// frame ke area rig yang tetap (mis. mangkuk) saat isolasi Vision gagal.
    static func jpeg(
        from input: VisionInput,
        orientation: CGImagePropertyOrientation = .right,
        cropRect: CGRect? = nil,
        maxDimension: CGFloat = 640,
        quality: CGFloat = 0.6
    ) -> Data? {
        switch input {
        case .image(let image):
            return jpeg(from: image, maxDimension: maxDimension, quality: quality)

        case .pixelBuffer(let buffer):
            let oriented = CIImage(cvPixelBuffer: buffer).oriented(orientation)

            let target: CIImage
            if let cropRect {
                let extent = oriented.extent
                let pixelRect = CGRect(
                    x: cropRect.minX * extent.width,
                    y: cropRect.minY * extent.height,
                    width: cropRect.width * extent.width,
                    height: cropRect.height * extent.height
                ).integral
                target = oriented.cropped(to: pixelRect)
            } else {
                target = oriented
            }

            guard let cgImage = ciContext.createCGImage(target, from: target.extent) else {
                return nil
            }
            return jpeg(from: cgImage, maxDimension: maxDimension, quality: quality)

        case .unavailable:
            return nil
        }
    }

    /// Skalakan supaya sisi terpanjang ≤ `maxDimension`. `nil` kalau gagal;
    /// pemanggil jatuh ke gambar asli.
    private static func resized(_ image: CGImage, maxDimension: CGFloat) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let longest = max(width, height)
        guard longest > maxDimension, longest > 0 else { return image }

        let scale = maxDimension / longest
        let newWidth = max(1, Int(width * scale))
        let newHeight = max(1, Int(height * scale))

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage()
    }
}
