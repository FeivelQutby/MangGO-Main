//
//  GradeAudioPlayer.swift
//  MangGO
//

import AVFoundation

/// Memutar satu file suara per grade saat `ResultScreen` muncul.
///
/// Tidak ada aset baru yang ditambahkan di sini — kelas ini hanya memetakan
/// `GradeDisplay` ke berkas MP3 yang **sudah** ada di `MangGO/Sound`
/// (`GRADE_A`, `GRADE_B`, `GRADE_C`, `REJECTED`). Folder itu ikut ke bundle
/// lewat synchronized folder group di project, jadi tidak perlu entri manual di
/// build phase Resources.
///
/// Singleton karena hanya boleh ada satu suara berbunyi pada satu waktu: dua
/// buah yang selesai beruntun tidak boleh saling menimpa jadi bunyi tumpang
/// tindih. Pemutar sebelumnya selalu dihentikan lebih dulu.
@MainActor
final class GradeAudioPlayer {

    static let shared = GradeAudioPlayer()

    private var player: AVAudioPlayer?
    private var sessionReady = false

    private init() {}

    // MARK: - Pemetaan berkas

    /// Nama berkas di `MangGO/Sound`, tanpa ekstensi.
    private func resourceName(for grade: GradeDisplay) -> String {
        switch grade {
        case .a: "GRADE_A"
        case .b: "GRADE_B"
        case .c: "GRADE_C"
        case .reject: "REJECTED"
        }
    }

    /// Tergantung cara folder `Sound` masuk ke target, resource bisa mendarat di
    /// akar bundle atau tetap di subfolder `Sound`. Keduanya dicoba supaya suara
    /// tidak diam-diam hilang kalau struktur bundle berubah.
    private func url(for grade: GradeDisplay) -> URL? {
        let name = resourceName(for: grade)
        return Bundle.main.url(forResource: name, withExtension: "mp3")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sound")
    }

    // MARK: - Kendali

    /// Mulai memutar suara untuk `grade`. Aman dipanggil berulang: pemutaran
    /// yang masih jalan dihentikan lebih dulu.
    func play(_ grade: GradeDisplay) {
        guard let url = url(for: grade) else {
            print("🔇 Berkas suara untuk grade \(grade.rawValue) tidak ada di bundle")
            return
        }

        activateSessionIfNeeded()

        player?.stop()

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
            print("🔊 Memutar \(url.lastPathComponent)")
        } catch {
            print("🔇 Gagal memutar \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    /// Dipanggil saat layar hasil ditutup — baik oleh tombol X maupun oleh timer
    /// auto-dismiss — supaya suara tidak terus berbunyi di layar berikutnya.
    func stop() {
        player?.stop()
        player = nil
    }

    // MARK: - Audio session

    /// `.playback` supaya pengumuman tetap terdengar walau iPad dalam mode
    /// senyap: layar hasil dipakai di lantai produksi dan operator mengandalkan
    /// bunyinya. `.duckOthers` mengecilkan audio lain sebentar, bukan
    /// menghentikannya. Hanya disiapkan sekali per proses.
    private func activateSessionIfNeeded() {
        guard !sessionReady else { return }

        #if !os(macOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            sessionReady = true
        } catch {
            print("🔇 Gagal menyiapkan AVAudioSession: \(error.localizedDescription)")
        }
        #else
        sessionReady = true
        #endif
    }
}
