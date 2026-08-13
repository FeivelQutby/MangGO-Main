import Foundation

enum GradeIndicator: String, Codable, CaseIterable, Sendable {
    case defect
    case mass
    case color
    case spots
    case blush
    case hue
    case saturation
    case brightness
    case volume

    var displayName: String {
        switch self {
        case .defect, .spots: "Bintik / Defek"
        case .mass: "Berat"
        case .color: "Warna"
        case .blush: "Blush"
        case .hue: "Hue"
        case .saturation: "Saturasi"
        case .brightness: "Kecerahan"
        case .volume: "Volume"
        }
    }
}

struct GradeResult: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var sampleID: UUID
    var grade: Grade
    var totalScore: Double
    var evaluatedAt = Date.now
    var reasons: [Reason]
    var isDisqualified: Bool = false
    var disqualificationReason: String? = nil

    struct Reason: Identifiable, Codable, Hashable, Sendable {
        var id: GradeIndicator { indicator }
        var indicator: GradeIndicator
        var grade: Grade
        var score: Double
        var weight: Double
        var detail: String
    }
}

extension GradeResult {
    /// Indikator yang menahan grade di level saat ini atau faktor penyebab diskualifikasi.
    var limitingFactors: [Reason] {
        if isDisqualified, let disqualificationReason {
            return [Reason(indicator: .defect, grade: .rejected, score: 0, weight: 0.4, detail: disqualificationReason)]
        }
        return reasons.filter { $0.grade == grade && grade != .a }
    }
}

