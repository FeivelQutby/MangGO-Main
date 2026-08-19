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

    /// Denyut halus menggantikan `symbolEffect(.pulse)` yang dulu dipakai —
    /// efek itu hanya berlaku untuk SF Symbol, bukan ilustrasi dari aset.
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 32) {
            Image("while_grading")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .opacity(isPulsing ? 0.65 : 1.0)
                .animation(
                    .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .onAppear { isPulsing = true }

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
