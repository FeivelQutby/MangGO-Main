import Foundation

/// Rentang nilai yang memetakan satu pengukuran ke satu grade.
struct GradeBand: Sendable {
    var grade: Grade
    var range: ClosedRange<Double>
}

extension Array where Element == GradeBand {
    /// Band pertama yang cocok menang, jadi urutkan dari grade terbaik.
    /// Nilai di luar semua band dianggap `.rejected`.
    func grade(for value: Double) -> Grade {
        first { $0.range.contains(value) }?.grade ?? .rejected
    }
}

protocol GradingCriterion: Sendable {
    var indicator: GradeIndicator { get }
    func evaluate(_ sample: MangoSample) -> GradeResult.Reason?
}

/// Kriteria yang menilai satu angka terhadap sekumpulan band.
struct MetricCriterion: GradingCriterion {
    var indicator: GradeIndicator
    var bands: [GradeBand]
    var detailFormat: String
    var measure: @Sendable (MangoSample) -> Double?

    func evaluate(_ sample: MangoSample) -> GradeResult.Reason? {
        guard let value = measure(sample) else { return nil }
        return GradeResult.Reason(
            indicator: indicator,
            grade: bands.grade(for: value),
            detail: String(format: detailFormat, value)
        )
    }
}
