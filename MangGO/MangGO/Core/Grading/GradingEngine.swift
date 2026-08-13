import Foundation

/// Menilai `MangoSample` menggunakan sistem skor ternormalisasi (0...100)
/// berdasarkan 3 parameter utama: Defek (40%), Berat (30%), dan Warna (30%).
struct GradingEngine: Sendable {
    var standard: GradingStandard
    var criteria: [any GradingCriterion]

    init(standard: GradingStandard = .harumManis) {
        self.standard = standard
        self.criteria = [
            NormalizedCriterion(
                indicator: .defect,
                weight: standard.defectWeight,
                detailFormatter: { sample in
                    let val = sample.spotCoverage ?? 0
                    return String(format: "%.1f%% bintik", val)
                },
                scoreCalculator: { sample in
                    guard let spot = sample.spotCoverage else { return nil }
                    return standard.scoreDefect(spotCoverage: spot)
                },
                standard: standard
            ),
            NormalizedCriterion(
                indicator: .mass,
                weight: standard.massWeight,
                detailFormatter: { sample in
                    let val = sample.mass ?? 0
                    return String(format: "%.0f g", val)
                },
                scoreCalculator: { sample in
                    guard let mass = sample.mass else { return nil }
                    return standard.scoreMass(grams: mass)
                },
                standard: standard
            ),
            NormalizedCriterion(
                indicator: .color,
                weight: standard.colorWeight,
                detailFormatter: { sample in
                    guard let c = sample.color else { return "—" }
                    return String(format: "H:%.0f Blush:%.0f%%", c.hue, c.blushCoverage)
                },
                scoreCalculator: { sample in
                    guard let color = sample.color else { return nil }
                    return standard.scoreColor(profile: color)
                },
                standard: standard
            )
        ]
    }

    init(criteria: [any GradingCriterion], standard: GradingStandard = .harumManis) {
        self.criteria = criteria
        self.standard = standard
    }

    func evaluate(_ sample: MangoSample) -> GradeResult? {
        let reasons = criteria.compactMap { $0.evaluate(sample) }
        guard !reasons.isEmpty else { return nil }

        // Hitung total skor berbobot dari kriteria yang tersedia
        let totalWeight = reasons.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }

        let weightedScoreSum = reasons.reduce(0.0) { $0 + ($1.score * $1.weight) }
        let totalScore = weightedScoreSum / totalWeight

        // Evaluasi diskualifikasi kritis
        var isDisqualified = false
        var disqualificationReason: String? = nil

        if let spot = sample.spotCoverage, spot > standard.maxDefectDisqualification {
            isDisqualified = true
            disqualificationReason = String(format: "Bintik/Defek melebihi batas (%.1f%%)", spot)
        } else if let mass = sample.mass, mass < standard.minMassDisqualification {
            isDisqualified = true
            disqualificationReason = String(format: "Berat di bawah standar (%.0f g)", mass)
        }

        let calculatedGrade = standard.grade(forScore: totalScore)
        let finalGrade: Grade = isDisqualified ? .rejected : calculatedGrade

        return GradeResult(
            sampleID: sample.id,
            grade: finalGrade,
            totalScore: totalScore,
            reasons: reasons,
            isDisqualified: isDisqualified,
            disqualificationReason: disqualificationReason
        )
    }
}

