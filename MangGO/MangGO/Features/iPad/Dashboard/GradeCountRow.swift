//
//  GradeCountRow.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Rekap jumlah buah per grade sepanjang sesi.
struct GradeCountRow: View {

    let counts: [String: Int]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(GradeDisplay.allCases) { grade in
                VStack(spacing: 8) {
                    Text(grade.rawValue).font(.headline).foregroundStyle(grade.color)
                    Text("\(counts[grade.rawValue] ?? 0)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(grade.color.opacity(0.12), in: .rect(cornerRadius: 20))
            }
        }
    }
}

#Preview {
    GradeCountRow(counts: ["A": 12, "B": 5, "C": 2, "Reject": 1]).padding()
}
