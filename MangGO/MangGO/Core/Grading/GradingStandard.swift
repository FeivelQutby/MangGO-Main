import Foundation

/// Standar dan aturan ambang batas normalisasi grading Harum Manis.
///
/// Parameter & Bobot Penilaian:
/// - Defek (Spot Coverage): 40% (0.40)
/// - Berat (Mass): 30% (0.30)
/// - Warna (Color / HSV & Blush): 30% (0.30)
///
/// Klasifikasi Grade berdasarkan Total Skor (0...100):
/// - Grade A : Total Skor >= 85
/// - Grade B : 70 <= Total Skor < 85
/// - Grade C : 50 <= Total Skor < 70
/// - Rejected: Total Skor < 50 (atau jika terkena diskualifikasi)
struct GradingStandard: Sendable {
    // Bobot penilaian (Total = 1.0)
    var defectWeight: Double = 0.40
    var massWeight: Double = 0.30
    var colorWeight: Double = 0.30

    // Threshold skor grade
    var gradeAThreshold: Double = 85.0
    var gradeBThreshold: Double = 70.0
    var gradeCThreshold: Double = 50.0

    // Batas diskualifikasi fatal
    var maxDefectDisqualification: Double = 30.0
    var minMassDisqualification: Double = 200.0

    static let harumManis = GradingStandard()

    /// Memetakan skor (0...100) ke Grade
    func grade(forScore score: Double) -> Grade {
        if score >= gradeAThreshold {
            return .a
        } else if score >= gradeBThreshold {
            return .b
        } else if score >= gradeCThreshold {
            return .c
        } else {
            return .rejected
        }
    }

    /// Normalisasi persentase cacat/bintik (0...100%) ke skor kualitas (0...100)
    func scoreDefect(spotCoverage: Double) -> Double {
        let d = max(0.0, spotCoverage)
        if d <= 5.0 {
            // 0% -> 100, 5% -> 85
            return 100.0 - (d / 5.0) * 15.0
        } else if d <= 15.0 {
            // 5% -> 85, 15% -> 70
            return 85.0 - ((d - 5.0) / 10.0) * 15.0
        } else if d <= 30.0 {
            // 15% -> 70, 30% -> 50
            return 70.0 - ((d - 15.0) / 15.0) * 20.0
        } else {
            // >30% -> skor < 50
            return max(0.0, 50.0 - ((d - 30.0) / 20.0) * 50.0)
        }
    }

    /// Normalisasi berat dalam gram ke skor ukuran komersial (0...100)
    func scoreMass(grams: Double) -> Double {
        let m = max(0.0, grams)
        if m >= 450.0 {
            return 100.0
        } else if m >= 400.0 {
            // 400g -> 85, 450g -> 100
            return 85.0 + ((m - 400.0) / 50.0) * 15.0
        } else if m >= 350.0 {
            // 350g -> 70, 400g -> 85
            return 70.0 + ((m - 350.0) / 50.0) * 15.0
        } else if m >= 280.0 {
            // 280g -> 50, 350g -> 70
            return 50.0 + ((m - 280.0) / 70.0) * 20.0
        } else {
            // <280g -> skor < 50
            return max(0.0, (m / 280.0) * 50.0)
        }
    }

    /// Normalisasi warna (HSV & Blush) ke skor kematangan dan visual (0...100)
    func scoreColor(profile: ColorProfile) -> Double {
        // 1. Hue Score (Bobot 50% dari skor warna)
        // Hue OpenCV (0...179): Harum manis matang 15...33, cukup matang 33...43, muda 43...55
        let h = profile.hue
        let hueScore: Double
        if h >= 15.0 && h <= 33.0 {
            hueScore = 100.0
        } else if h > 33.0 && h <= 43.0 {
            hueScore = 85.0 - ((h - 33.0) / 10.0) * 15.0 // 85...70
        } else if h > 43.0 && h <= 55.0 {
            hueScore = 70.0 - ((h - 43.0) / 12.0) * 20.0 // 70...50
        } else if h < 15.0 {
            hueScore = max(0.0, 100.0 - (15.0 - h) * 5.0)
        } else {
            hueScore = max(0.0, 50.0 - (h - 55.0) * 2.5)
        }

        // 2. Blush Score (Bobot 25% dari skor warna)
        let b = profile.blushCoverage
        let blushScore: Double
        if b >= 15.0 {
            blushScore = 100.0
        } else if b >= 5.0 {
            blushScore = 70.0 + ((b - 5.0) / 10.0) * 15.0 // 70...85
        } else if b >= 0.5 {
            blushScore = 50.0 + ((b - 0.5) / 4.5) * 20.0 // 50...70
        } else {
            blushScore = max(30.0, (b / 0.5) * 50.0)
        }

        // 3. Vibrancy (Saturasi & Brightness) (Bobot 25% dari skor warna)
        let sat = profile.saturation
        let satScore: Double
        if sat >= 76.0 {
            satScore = 100.0
        } else if sat >= 64.0 {
            satScore = 70.0 + ((sat - 64.0) / 12.0) * 15.0
        } else {
            satScore = max(0.0, (sat / 64.0) * 70.0)
        }

        let br = profile.brightness
        let brScore: Double
        if br >= 178.0 {
            brScore = 100.0
        } else if br >= 128.0 {
            brScore = 70.0 + ((br - 128.0) / 50.0) * 15.0
        } else if br >= 64.0 {
            brScore = 50.0 + ((br - 64.0) / 64.0) * 20.0
        } else {
            brScore = max(0.0, (br / 64.0) * 50.0)
        }

        let vibrancyScore = 0.5 * satScore + 0.5 * brScore
        let totalColorScore = 0.50 * hueScore + 0.25 * blushScore + 0.25 * vibrancyScore

        return min(max(totalColorScore, 0.0), 100.0)
    }
}

