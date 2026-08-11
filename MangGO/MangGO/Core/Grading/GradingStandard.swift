import Foundation

/// Ambang batas grading Harum Manis.
///
/// Band diurutkan dari grade terbaik dan dicek berurutan, jadi nilai tepat di
/// perbatasan jatuh ke grade yang lebih baik. Nilai di luar semua band otomatis
/// `.rejected` — itulah cara ekstrem atas dan bawah ditangani tanpa band khusus.
///
/// Ini dibuat based on grading table yang ada di MIRO
struct GradingStandard: Sendable {
    var spotCoverage: [GradeBand]
    var blushCoverage: [GradeBand]
    var hue: [GradeBand]
    var saturation: [GradeBand]
    var brightness: [GradeBand]
    var mass: [GradeBand]
    var volume: [GradeBand]

    static let harumManis = GradingStandard(
        spotCoverage: [
            GradeBand(grade: .a, range: 0...5),
            GradeBand(grade: .b, range: 5...15),
            GradeBand(grade: .c, range: 15...30)
        ],
        blushCoverage: [
            GradeBand(grade: .a, range: 15...40),
            GradeBand(grade: .b, range: 5...15),
            GradeBand(grade: .c, range: 0.5...5)
        ],
        hue: [
            GradeBand(grade: .a, range: 15...33),
            GradeBand(grade: .b, range: 33...43),
            GradeBand(grade: .c, range: 43...55)
        ],
        saturation: [
            GradeBand(grade: .a, range: 76...255),
            GradeBand(grade: .b, range: 64...76)
        ],
        brightness: [
            GradeBand(grade: .a, range: 178...255),
            GradeBand(grade: .b, range: 128...178),
            GradeBand(grade: .c, range: 64...128)
        ],
        mass: [
            GradeBand(grade: .a, range: 400...(.infinity)),
            GradeBand(grade: .b, range: 351...400),
            GradeBand(grade: .c, range: 0...351)
        ],
        volume: [
            GradeBand(grade: .a, range: 350...550),
            GradeBand(grade: .b, range: 280...350),
            GradeBand(grade: .c, range: 200...280)
        ]
    )
}
