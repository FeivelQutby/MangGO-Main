import Foundation

/// Menilai `MangoSample` terhadap sekumpulan kriteria independen.
///
/// Ini dibuat based on grading table yang ada di MIRO
struct GradingEngine: Sendable {
    var criteria: [any GradingCriterion]

    init(criteria: [any GradingCriterion]) {
        self.criteria = criteria
    }

    init(standard: GradingStandard = .harumManis) {
        self.criteria = [
            MetricCriterion(
                indicator: .spots,
                bands: standard.spotCoverage,
                detailFormat: "%.1f%% permukaan",
                measure: { $0.spotCoverage }
            ),
            MetricCriterion(
                indicator: .blush,
                bands: standard.blushCoverage,
                detailFormat: "%.1f%% permukaan",
                measure: { $0.color?.blushCoverage }
            ),
            MetricCriterion(
                indicator: .hue,
                bands: standard.hue,
                detailFormat: "H %.0f",
                measure: { $0.color?.hue }
            ),
            MetricCriterion(
                indicator: .saturation,
                bands: standard.saturation,
                detailFormat: "S %.0f",
                measure: { $0.color?.saturation }
            ),
            MetricCriterion(
                indicator: .brightness,
                bands: standard.brightness,
                detailFormat: "V %.0f",
                measure: { $0.color?.brightness }
            ),
            MetricCriterion(
                indicator: .mass,
                bands: standard.mass,
                detailFormat: "%.0f g",
                measure: { $0.mass }
            ),
            MetricCriterion(
                indicator: .volume,
                bands: standard.volume,
                detailFormat: "%.0f cm³",
                measure: { $0.volume }
            )
        ]
    }

    func evaluate(_ sample: MangoSample) -> GradeResult? {
        let reasons = criteria.compactMap { $0.evaluate(sample) }
        guard !reasons.isEmpty else { return nil }

        return GradeResult(
            sampleID: sample.id,
            grade: reasons.map(\.grade).reduce(Grade.a, Grade.worst),
            reasons: reasons
        )
    }
}
