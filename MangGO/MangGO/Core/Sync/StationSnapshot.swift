//
//  StationSnapshot.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import Foundation

struct StationSnapshot: Codable, Sendable, Equatable {

    enum Phase: String, Codable, Sendable {
        case idle, scanningFront, flipping, weighing, scanningBack, done

        var isWorking: Bool { self != .idle && self != .done }

        var progress: Double {
            switch self {
            case .idle: 0
            case .scanningFront: 0.25
            case .flipping: 0.5
            case .weighing: 0.7
            case .scanningBack: 0.9
            case .done: 1
            }
        }

        var label: String {
            switch self {
            case .idle: "Menunggu Mangga"
            case .scanningFront: "Memindai..."
            case .flipping: "Membalik Mangga..."
            case .weighing: "Menimbang..."
            case .scanningBack: "Memindai..."
            case .done: "Selesai"
            }
        }
    }

    struct Sensors: Codable, Sendable, Equatable {
        enum State: String, Codable, Sendable {
            case ready
            case waiting
            case offline
        }

        var loadCell: State = .offline
        var servo: State = .offline
        var camera: State = .offline
        var bluetooth: State = .offline

        var allReady: Bool {
            [
                loadCell,
                servo,
                camera,
                bluetooth
            ].allSatisfy { $0 == .ready }
        }

        static let allReady = Sensors(
            loadCell: .ready,
            servo: .ready,
            camera: .ready,
            bluetooth: .ready
        )
    }

    struct Result: Codable, Sendable, Equatable {
        var id: UUID
        var grade: String
        var reason: String?
        var score: Double?
        var weightGrams: Double?
        var defectPercent: Double?
        var gradedAt: Date

        /// Foto dokumentasi (JPEG) untuk mangga **reject** saja. Sisi A = capture
        /// pertama, sisi B = capture kedua setelah flip. `nil` untuk grade lain
        /// dan dibuang saat snapshot dibawa maju ke fase berikutnya supaya tidak
        /// dikirim ulang berkali-kali di link lokal.
        var imageA: Data?
        var imageB: Data?
    }
    var phase: Phase = .idle
    var lastResult: Result?
    var counts: [String: Int] = [:]
    var sensors: Sensors = .init()
    var updatedAt: Date = .distantPast

    static let idle = StationSnapshot()
}
