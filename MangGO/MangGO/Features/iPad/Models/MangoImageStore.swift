//
//  MangoImageStore.swift
//  MangGO
//

import Foundation
import UIKit

/// Menyimpan foto dokumentasi mangga reject di disk, dikunci `MangoRecord.id`.
///
/// Sengaja **tidak** dititip di dalam `MangoRecord` (yang di-encode ke
/// UserDefaults): base64 JPEG untuk tiap reject akan membengkakkan UserDefaults.
/// Di sini file JPEG ditulis ke Application Support, dan detail view memuatnya
/// ulang lewat id yang sama. Foto datang dari iPhone lewat `StationSnapshot`.
@MainActor
final class MangoImageStore {

    static let shared = MangoImageStore()

    enum Side: String {
        case a = "A"
        case b = "B"
    }

    private let directory: URL

    init() {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        directory = base.appendingPathComponent("MangoRejectPhotos", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    private func url(_ id: UUID, _ side: Side) -> URL {
        directory.appendingPathComponent("\(id.uuidString)_\(side.rawValue).jpg")
    }

    // MARK: - Save

    /// Tiap sisi ditulis terpisah supaya kegagalan salah satu tidak ikut
    /// membatalkan yang lain — mangga reject dengan satu sisi tetap lebih
    /// berguna daripada tanpa foto sama sekali.
    func save(id: UUID, sideA: Data?, sideB: Data?) {
        write(sideA, id: id, side: .a)
        write(sideB, id: id, side: .b)
    }

    private func write(_ data: Data?, id: UUID, side: Side) {
        guard let data else {
            print("ℹ️ Foto sisi \(side.rawValue) untuk \(id) tidak dikirim")
            return
        }

        do {
            try data.write(to: url(id, side), options: .atomic)
            print("💾 Foto sisi \(side.rawValue) tersimpan (\(data.count) B) untuk \(id)")
        } catch {
            print("❌ Gagal menyimpan foto sisi \(side.rawValue): \(error.localizedDescription)")
        }
    }

    // MARK: - Load

    func image(id: UUID, side: Side) -> UIImage? {
        guard let data = try? Data(contentsOf: url(id, side)) else { return nil }
        return UIImage(data: data)
    }

    func hasImage(id: UUID, side: Side) -> Bool {
        FileManager.default.fileExists(atPath: url(id, side).path)
    }

    func hasImages(id: UUID) -> Bool {
        hasImage(id: id, side: .a) || hasImage(id: id, side: .b)
    }

    // MARK: - Debug

    func clearAll() {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }
}
