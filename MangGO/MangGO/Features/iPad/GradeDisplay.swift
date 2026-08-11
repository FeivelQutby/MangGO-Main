//
//  GradeDisplay.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//


import SwiftUI

enum GradeDisplay: String, CaseIterable, Identifiable {
    case a = "A"
    case b = "B"
    case c = "C"
    case reject = "Reject"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .a: Color(red: 0.35, green: 0.78, blue: 0.42)
        case .b: Color(red: 0.91, green: 0.58, blue: 0.24)
        case .c: Color(red: 0.96, green: 0.81, blue: 0.24)
        case .reject: Color(red: 0.91, green: 0.36, blue: 0.36)
        }
    }

    var headline: String {
        self == .reject ? "REJECT" : "GRADE \(rawValue)"
    }
}
