import Foundation

/// Memilih detektor dan isolator saat runtime.
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

    /// Isolasi buah tidak bergantung pada model bundle — Vision selalu ada.
    /// Yang tidak ada adalah Neural Engine di Simulator: di sana
    /// `VNGenerateForegroundInstanceMaskRequest` gagal membuat inference
    /// context, jadi jalur mock dipakai supaya demo tanpa device tetap jalan.
    nonisolated static func makeIsolator() -> any FruitIsolating {
        #if targetEnvironment(simulator)
        return MockFruitIsolator()
        #else
        return VisionFruitIsolator()
        #endif
    }
}
