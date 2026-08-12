import Foundation
import CoreGraphics

/// Salinan RGBA8 dari sebuah `CGImage` pada resolusi kerja tertentu.
///
/// Analisis warna dan pemilihan instance dilakukan di resolusi rendah yang sama
/// dengan `instanceMask` dari Vision, supaya mask dan piksel warna bisa
/// di-index dengan offset yang sama tanpa penskalaan tambahan.
struct RGBBitmap: Sendable {
    let width: Int
    let height: Int
    private let pixels: [UInt8] // RGBA, 4 byte per piksel

    init?(image: CGImage, width: Int, height: Int) {
        guard width > 0, height > 0 else { return nil }

        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        let drawn = buffer.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { return false }

            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        guard drawn else { return nil }
        self.width = width
        self.height = height
        self.pixels = buffer
    }

    /// Warna piksel pada indeks linear yang sama dengan `PixelMask.values`.
    func color(at index: Int) -> (r: Double, g: Double, b: Double) {
        let offset = index * 4
        return (
            Double(pixels[offset]) / 255,
            Double(pixels[offset + 1]) / 255,
            Double(pixels[offset + 2]) / 255
        )
    }
}

/// HSV dengan hue dalam derajat (0...360), saturasi dan value 0...1.
struct HSV: Sendable {
    var hue: Double
    var saturation: Double
    var value: Double

    init(r: Double, g: Double, b: Double) {
        let maxComponent = max(r, g, b)
        let minComponent = min(r, g, b)
        let delta = maxComponent - minComponent

        value = maxComponent
        saturation = maxComponent > 0 ? delta / maxComponent : 0

        guard delta > 0 else {
            hue = 0
            return
        }

        let raw: Double
        switch maxComponent {
        case r: raw = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
        case g: raw = 60 * (((b - r) / delta) + 2)
        default: raw = 60 * (((r - g) / delta) + 4)
        }
        hue = raw < 0 ? raw + 360 : raw
    }
}
