//
//  EmptyStateView.swift
//  MangGO
//
//  Created for Manda Scope (Manager Dashboard Empty States)
//

import SwiftUI

/// Tampilan Kosong (Empty State) reusable untuk Data Harian (Kosong) dan Data Tren (Kosong)
struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(Color.blue)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))

                Text(subtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(Color(red: 60/255, green: 60/255, blue: 67/255))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
    }
}

#Preview("Data Harian Kosong") {
    EmptyStateView(
        title: "Belum Ada Data Hari Ini",
        subtitle: "Mangga belum di-grade hari ini. Data harian akan muncul otomatis setelah proses grading pertama.",
        icon: "tray"
    )
}

#Preview("Data Tren Kosong") {
    EmptyStateView(
        title: "Belum Ada Data Tren",
        subtitle: "Data historis belum tersedia. Terus lakukan grading untuk melihat analisis tren rentang waktu.",
        icon: "chart.bar"
    )
}

