//
//  GradeDisplay.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Representasi visual grade di layar iPad — warna dan judul besar.
enum GradeDisplay: String, CaseIterable, Identifiable {
    case a = "A"
    case b = "B"
    case c = "C"
    case reject = "Reject"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .a: Color(red: 52/255, green: 199/255, blue: 89/255)
        case .b: Color(red: 255/255, green: 141/255, blue: 40/255)
        case .c: Color(red: 255/255, green: 204/255, blue: 0/255)
        case .reject: Color(red: 255/255, green: 98/255, blue: 101/255)
        }
    }

    var headline: String {
        self == .reject ? "REJECT" : "GRADE \(rawValue)"
    }
}

extension StationSnapshot {

    /// Grade buah yang baru saja selesai dinilai, atau `nil` kalau alat masih
    /// bekerja / belum ada hasil. Dipakai untuk memicu overlay hasil.
    var completedGrade: GradeDisplay? {
        guard phase == .done, let raw = lastResult?.grade else { return nil }
        return GradeDisplay(rawValue: raw)
    }
}
