import Foundation

enum Grade: String, Codable, CaseIterable, Sendable {
    case a
    case b
    case c
    case rejected

    var displayName: String {
        switch self {
        case .a: "Grade A"
        case .b: "Grade B"
        case .c: "Grade C"
        case .rejected: "Rejected"
        }
    }

    /// Makin kecil makin baik.
    var rank: Int {
        switch self {
        case .a: 0
        case .b: 1
        case .c: 2
        case .rejected: 3
        }
    }

    static func worst(_ lhs: Grade, _ rhs: Grade) -> Grade {
        lhs.rank >= rhs.rank ? lhs : rhs
    }
}

extension Grade {
    /// Kode yang dikirim ke iPad lewat `StationSnapshot.Result.grade`.
    /// Harus cocok persis dengan `GradeDisplay.rawValue`.
    var displayCode: String {
        switch self {
        case .a: "A"
        case .b: "B"
        case .c: "C"
        case .rejected: "Reject"
        }
    }
}
