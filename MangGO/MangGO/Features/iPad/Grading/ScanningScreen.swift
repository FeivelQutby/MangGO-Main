//
//  ScanningScreen.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Layar saat alat sedang memproses satu buah.
struct ScanningScreen: View {

    let phase: StationSnapshot.Phase

    var body: some View {
        VStack(spacing: 32) {
            // Ganti dengan Image("mango-illustration") setelah aset masuk.
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 120))
                .foregroundStyle(.orange)
                .frame(height: 200)
                .symbolEffect(.pulse)

            // Progress meloncat per fase, bukan mengalir dari timer — bar yang
            // halus saat sistem macet di weighing akan menyesatkan worker.
            ProgressView(value: phase.progress)
                .tint(.green)
                .frame(width: 340)

            Text(phase.label).font(.system(size: 34, weight: .bold))
        }
        .padding(40)
    }
}

#Preview { ScanningScreen(phase: .weighing) }
