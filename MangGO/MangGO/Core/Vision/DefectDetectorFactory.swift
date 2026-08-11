import Foundation

/// Memilih detektor saat runtime.
///
/// Selama `MangoDefect.mlmodelc` belum ada di bundle, `CoreMLDefectDetector`
/// selalu melempar `.modelUnavailable`, artinya siklus grading tidak pernah
/// sampai `.finished` dan iPad tidak pernah menerima hasil. Jadi app jatuh ke
/// mock supaya alur iPhone → iPad tetap bisa diuji end-to-end, lalu naik
/// sendiri ke Core ML begitu model dimasukkan ke `Core/Vision/Resources/`.
enum DefectDetectorFactory {

    nonisolated static var hasBundledModel: Bool {
        Bundle.main.url(forResource: "MangoDefect", withExtension: "mlmodelc") != nil
    }

    /// `nonisolated` supaya bisa dipakai sebagai property initializer di View,
    /// yang dievaluasi di luar isolasi MainActor.
    nonisolated static func make() -> any DefectDetecting {
        if hasBundledModel {
            return CoreMLDefectDetector()
        }
        return MockDefectDetector()
    }
}
