//
//  ColorReading.swift
//  MangGO
//

import SwiftUI

/// Menerjemahkan `ColorProfile` hasil pengukuran jadi sesuatu yang bisa dibaca
/// operator: nama warna, contoh warnanya, dan kematangannya.
///
/// Ambang di sini **sengaja mengikuti** `GradingStandard.scoreColor(profile:)`.
/// Kalau keduanya dibiarkan punya angka sendiri, layar detail bisa menulis
/// "kematangan optimal" untuk buah yang justru dihukum mesin grading — dan
/// operator akan berhenti mempercayai layarnya. Setiap kali ambang hue di
/// `GradingStandard` diubah, tabel di `Ripeness.init(hue:)` harus ikut diubah.
///
/// Ada di lapisan Features, bukan Core, karena butuh SwiftUI: `ColorProfile`
/// sendiri hanya bergantung pada Foundation.
extension ColorProfile {

    /// Kematangan menurut hue, memakai batas yang sama dengan skor warna.
    enum Ripeness {
        /// Hue di bawah rentang optimal — sudah lewat matang, kulit kemerahan.
        case overripe
        /// 15...33 pada skala OpenCV: skor hue penuh.
        case optimal
        /// 33...43: masih diterima tapi mulai dihukum.
        case nearlyRipe
        /// 43...55: muda.
        case unripe
        /// Di atas 55: terlalu hijau, skor hue jatuh cepat.
        case tooGreen

        init(hue: Double) {
            switch hue {
            case ..<15: self = .overripe
            case 15...33: self = .optimal
            case 33...43: self = .nearlyRipe
            case 43...55: self = .unripe
            default: self = .tooGreen
            }
        }

        var label: String {
            switch self {
            case .overripe: "terlalu matang"
            case .optimal: "kematangan optimal"
            case .nearlyRipe: "cukup matang"
            case .unripe: "masih muda"
            case .tooGreen: "terlalu hijau"
            }
        }

        /// Hanya dua ujung ekstrem yang benar-benar menurunkan skor warna;
        /// sisanya masih dalam rentang yang diterima standar.
        var isProblem: Bool {
            self == .overripe || self == .tooGreen
        }
    }

    var ripeness: Ripeness { Ripeness(hue: hue) }

    /// Nama warna dalam bahasa operator, bukan angka hue.
    ///
    /// Hue di sini skala OpenCV (0...179); dikalikan 2 jadi derajat. Batasnya
    /// dipilih pada peralihan warna yang terlihat mata, jadi tidak persis sama
    /// dengan batas kematangan di atas — satu buah bisa "oranye" sekaligus
    /// "kematangan optimal".
    var displayName: String {
        switch hue {
        case ..<12: "merah"                 // < 24°
        case 12..<22: "oranye"              // 24°...44°
        case 22..<35: "kuning"              // 44°...70°
        case 35..<48: "kuning kehijauan"    // 70°...96°
        default: "hijau"                    // >= 96°
        }
    }

    /// Warna sungguhan yang terukur, untuk titik contoh di kartu.
    ///
    /// Dibangun dari HSV yang sama yang dipakai menilai, jadi kalau titiknya
    /// terlihat aneh — abu-abu, biru, terlalu gelap — itu bukan bug tampilan
    /// melainkan tanda mask-nya menangkap sesuatu yang bukan kulit buah.
    /// Konversi dari konvensi OpenCV: H 0...179, S dan V 0...255.
    var swatch: Color {
        Color(
            hue: min(max(hue / 179, 0), 1),
            saturation: min(max(saturation / 255, 0), 1),
            brightness: min(max(brightness / 255, 0), 1)
        )
    }
}
