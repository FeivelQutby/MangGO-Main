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

    func save(id: UUID, sideA: Data?, sideB: Data?) {
        if let sideA {
            try? sideA.write(to: url(id, .a), options: .atomic)
        }
        if let sideB {
            try? sideB.write(to: url(id, .b), options: .atomic)
        }
    }

    // MARK: - Load

    func image(id: UUID, side: Side) -> UIImage? {
        guard let data = try? Data(contentsOf: url(id, side)) else { return nil }
        return UIImage(data: data)
    }

    func hasImages(id: UUID) -> Bool {
        FileManager.default.fileExists(atPath: url(id, .a).path)
            || FileManager.default.fileExists(atPath: url(id, .b).path)
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
