//
//  SensorSummaryRow.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Ringkasan sensor versi padat — hanya titik warna, karena di dashboard
/// ruang sudah dipakai angka. Arti warnanya sama dengan di IdleScreen
/// (lihat `Shared/SensorStatus.swift`).
struct SensorSummaryRow: View {

    let sensors: StationSnapshot.Sensors

    var body: some View {
        HStack(spacing: 12) {
            chip("Load Cell", sensors.loadCell)
            chip("ToF", sensors.tof)
            chip("Camera", sensors.camera)
            chip("Bluetooth", sensors.bluetooth)
        }
    }

    private func chip(_ name: String,
                      _ state: StationSnapshot.Sensors.State) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(state.color)
                .frame(width: 10, height: 10)
            Text(name).font(.headline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: .capsule)
    }
}

#Preview {
    SensorSummaryRow(sensors: .allReady).padding()
}
