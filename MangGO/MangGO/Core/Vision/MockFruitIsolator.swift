import Foundation
import CoreGraphics

/// Jalur tanpa segmentasi nyata: Preview SwiftUI dan Simulator, di mana
/// `VNGenerateForegroundInstanceMaskRequest` tidak bisa membuat inference context.
///
/// `cropRect` sengaja seluruh frame dan mask-nya penuh, supaya bounding box mock
/// lewat tanpa diubah dan tanpa terbuang oleh filter mask.
struct MockFruitIsolator: FruitIsolating {
    var areaRatio: Double = 0.42
    var color = ColorProfile(hue: 28, saturation: 120, brightness: 190, blushCoverage: 22)

    func isolate(_ input: VisionInput) async throws -> FruitIsolation {
        FruitIsolation(
            image: Self.placeholder,
            cropRect: CGRect(x: 0, y: 0, width: 1, height: 1),
            areaRatio: areaRatio,
            color: color,
            mask: .filled(width: 32, height: 32),
            candidateCount: 1
        )
    }

    /// Konteks bitmap RGBA berukuran tetap tidak bisa gagal dibuat, jadi
    /// unwrap-nya aman dan tidak menyembunyikan kondisi runtime apa pun.
    nonisolated(unsafe) private static let placeholder: CGImage = {
        let side = 64
        let context = CGContext(
            data: nil,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0.55, green: 0.68, blue: 0.20, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        return context.makeImage()!
    }()
}
