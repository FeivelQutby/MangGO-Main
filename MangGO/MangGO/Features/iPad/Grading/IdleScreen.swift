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
                        SensorChip("sensor.tag.radiowaves.forward", "ToF", sensors.tof)
                    }
                    GridRow {
                        SensorChip("camera", "Camera", sensors.camera)
                        SensorChip("sensor.radiowaves.left.and.right", "Bluetooth", sensors.bluetooth)
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 20))
            }

            section("Mulai Grading Mangga") {
                HStack(spacing: 16) {
                    StepCard("1", "hand.point.down.fill", "Letakkan mangga di atas alat")
                    StepCard("2", "arrow.down.circle.fill", "Tekan tombol untuk mulai grading setiap mangga")
                    StepCard("3", "checkmark.seal.fill", "Tunggu dan lihat hasil grading")
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
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(state.backgroundColor, in: .capsule)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 320)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 14))
    }
}

private struct StepCard: View {

    let stepNumber: String
    let icon: String
    let text: String

    init(_ stepNumber: String, _ icon: String, _ text: String) {
        self.stepNumber = stepNumber
        self.icon = icon
        self.text = text
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 54, height: 54)
                Text(stepNumber)
                    .font(.title2.bold())
                    .foregroundStyle(Color.accentColor)
            }
            Text(text)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .padding(20)
        .frame(width: 220, height: 180)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview { IdleScreen(sensors: .allReady) }
