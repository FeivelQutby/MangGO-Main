import Foundation

/// Rentang nilai yang memetakan satu pengukuran ke satu grade (opsional / legacy band).
struct GradeBand: Sendable {
    var grade: Grade
    var range: ClosedRange<Double>
}

extension Array where Element == GradeBand {
    func grade(for value: Double) -> Grade {
        first { $0.range.contains(value) }?.grade ?? .rejected
    }
}

protocol GradingCriterion: Sendable {
    var indicator: GradeIndicator { get }
    var weight: Double { get }
    func evaluate(_ sample: MangoSample) -> GradeResult.Reason?
}

/// Kriteria penilaian ternormalisasi (skor 0...100).
struct NormalizedCriterion: GradingCriterion {
    var indicator: GradeIndicator
    var weight: Double
    var detailFormatter: @Sendable (MangoSample) -> String
    var scoreCalculator: @Sendable (MangoSample) -> Double?
    var standard: GradingStandard

    func evaluate(_ sample: MangoSample) -> GradeResult.Reason? {
        guard let score = scoreCalculator(sample) else { return nil }
        let clampedScore = min(max(score, 0.0), 100.0)
        let grade = standard.grade(forScore: clampedScore)
        let detail = detailFormatter(sample)

        return GradeResult.Reason(
            indicator: indicator,
            grade: grade,
            score: clampedScore,
            weight: weight,
            detail: detail
        )
    }
}

