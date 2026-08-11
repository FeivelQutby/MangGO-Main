//
//  IdleScreen.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Layar tunggu: status sensor + instruksi tiga langkah untuk operator.
struct IdleScreen: View {

    let sensors: StationSnapshot.Sensors

    var body: some View {
        VStack(spacing: 48) {
            section("Status Sensor") {
                Grid(horizontalSpacing: 16, verticalSpacing: 12) {
                    GridRow {
                        SensorChip("scalemass", "Load Cell", sensors.loadCell)
                        SensorChip("ruler", "ToF", sensors.tof)
                    }
                    GridRow {
                        SensorChip("camera", "Camera", sensors.camera)
                        SensorChip("dot.radiowaves.left.and.right", "Bluetooth", sensors.bluetooth)
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 20))
            }

            section("Mulai Grading Mangga") {
                HStack(spacing: 16) {
                    StepCard("hand.point.down.fill", "Letakkan mangga di atas alat")
                    StepCard("arrow.down.circle.fill", "Tekan tombol untuk mulai grading")
                    StepCard("checkmark.seal.fill", "Tunggu dan lihat hasil grading")
                }
            }
        }
        .padding(40)
    }

    private func section<C: View>(_ title: String,
                                  @ViewBuilder content: () -> C) -> some View {
        VStack(spacing: 16) {
            Text(title).font(.title3.weight(.bold))
            content()
        }
    }
}

/// Baris sensor versi lebar — dipakai hanya di IdleScreen, di mana ada ruang
/// untuk menuliskan status secara eksplisit.
private struct SensorChip: View {

    let icon: String
    let name: String
    let state: StationSnapshot.Sensors.State

    init(_ icon: String, _ name: String, _ state: StationSnapshot.Sensors.State) {
        self.icon = icon
        self.name = name
        self.state = state
    }

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.secondary)
            Text(name).font(.headline)
            Spacer(minLength: 24)
            Text(state.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(state.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(state.color.opacity(0.15), in: .capsule)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 300)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 14))
    }
}

private struct StepCard: View {

    let icon: String
    let text: String

    init(_ icon: String, _ text: String) {
        self.icon = icon
        self.text = text
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.tint)
                .frame(height: 80)
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 200, height: 200)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 20))
    }
}

#Preview { IdleScreen(sensors: .allReady) }
