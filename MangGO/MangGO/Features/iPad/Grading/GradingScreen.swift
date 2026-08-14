//
//  GradingScreen.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Router tab Grading: menentukan layar mana yang tampil berdasarkan state
/// koneksi dan fase alat. Layar hasil (`ResultScreen`) dipasang di `iPadView`
/// sebagai overlay, bukan di sini, supaya menutupi seluruh layar termasuk
/// tab picker.
struct GradingScreen: View {

    let snapshot: StationSnapshot
    let isLinked: Bool
    var connectionError: String? = nil

    var body: some View {

        if !isLinked {

            DisconnectedScreen(
                message: connectionError
            )

        } else if snapshot.phase.isWorking {

            ScanningScreen(
                phase: snapshot.phase
            )

        } else {

            IdleScreenView(
                snapshot: snapshot
            )
        }
    }
}

#Preview("Idle") {
    GradingScreen(
        snapshot: StationSnapshot(
            sensors: .allReady
        ),
        isLinked: true
    )
}

#Preview("Scanning") {
    GradingScreen(
        snapshot: StationSnapshot(
            phase: .weighing,
            sensors: .allReady
        ),
        isLinked: true
    )
}

#Preview("Disconnected") {
    GradingScreen(
        snapshot: .idle,
        isLinked: false,
        connectionError: "Koneksi terputus"
    )
}
