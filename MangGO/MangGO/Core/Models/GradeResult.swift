import Foundation

enum GradeIndicator: String, Codable, CaseIterable, Sendable {
    case spots
    case blush
    case hue
    case saturation
    case brightness
    case mass
    case volume

    var displayName: String {
        switch self {
        case .spots: "Bintik"
        case .blush: "Blush"
        case .hue: "Hue"
        case .saturation: "Saturasi"
        case .brightness: "Kecerahan"
        case .mass: "Berat"
        case .volume: "Volume"
        }
    }
}

struct GradeResult: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var sampleID: UUID
    var grade: Grade
    var evaluatedAt = Date.now
    var reasons: [Reason]

    struct Reason: Identifiable, Codable, Hashable, Sendable {
        var id: GradeIndicator { indicator }
        var indicator: GradeIndicator
        var grade: Grade
        var detail: String
    }
}

extension GradeResult {
    /// Indikator yang menahan grade di level saat ini.
    var limitingFactors: [Reason] {
        reasons.filter { $0.grade == grade && grade != .a }
    }
}
