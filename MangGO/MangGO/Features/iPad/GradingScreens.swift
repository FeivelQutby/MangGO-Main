//
//  GradingScreens.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//


// ubah di sini ya nda

import SwiftUI

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

struct ResultScreen: View {

    let grade: GradeDisplay
    let reason: String?

    var body: some View {
        ZStack {
            grade.color.ignoresSafeArea()
            VStack(spacing: 24) {
                Text(grade.headline)
                    .font(.system(size: 130, weight: .black))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                if let reason {
                    Text(reason).font(.system(size: 30, weight: .medium))
                }
            }
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .padding(48)
        }
    }
}

struct DisconnectedScreen: View {

    var message: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text("Menunggu iPhone Kamera").font(.system(size: 40, weight: .semibold))
            Text("Pastikan iPhone di dalam box menyala, Wi-Fi dan Bluetooth aktif.")
                .font(.title3)
                .foregroundStyle(.secondary)
            if let message {
                Label(message, systemImage: "wifi.exclamationmark")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
        }
        .multilineTextAlignment(.center)
        .padding(40)
    }
}

struct DashboardScreen: View {

    let snapshot: StationSnapshot

    private var counts: [String: Int] { snapshot.counts }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Total diproses: \(counts.values.reduce(0, +))")
                .font(.title2.weight(.semibold))

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

            Text("Buah Terakhir").font(.title3.weight(.bold))

            if let result = snapshot.lastResult {
                HStack(spacing: 16) {
                    MetricTile("Berat", value: result.weightGrams, unit: "g", digits: 0)
                    MetricTile("Volume", value: result.volumeCm3, unit: "cm³", digits: 0)
                    MetricTile("Blush", value: result.blushPercent, unit: "%", digits: 1)
                    MetricTile("Bintik", value: result.defectPercent, unit: "%", digits: 1)
                }

                HStack(spacing: 12) {
                    if let grade = GradeDisplay(rawValue: result.grade) {
                        Text(grade.headline)
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(grade.color, in: .capsule)
                    }
                    Text(result.reason ?? "Semua indikator dalam ambang batas")
                        .font(.title3)
                        .foregroundStyle(result.reason == nil ? Color.secondary : Color.orange)
                }
            } else {
                Text("Belum ada buah yang selesai dinilai.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text("Status Sensor").font(.title3.weight(.bold))
            SensorSummary(sensors: snapshot.sensors)

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MetricTile: View {

    let title: String
    let value: Double?
    let unit: String
    let digits: Int

    init(_ title: String, value: Double?, unit: String, digits: Int) {
        self.title = title
        self.value = value
        self.unit = unit
        self.digits = digits
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))
    }

    /// Unit digabung di luar `String(format:)` — kalau "%" masuk ke format
    /// string dia dibaca sebagai specifier dan hasilnya sampah.
    private var text: String {
        guard let value else { return "—" }
        return String(format: "%.\(digits)f", value) + " " + unit
    }
}

private struct SensorSummary: View {

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
                .fill(color(state))
                .frame(width: 10, height: 10)
            Text(name).font(.headline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: .capsule)
    }

    private func color(_ state: StationSnapshot.Sensors.State) -> Color {
        switch state {
        case .ready: .green
        case .waiting: .orange
        case .offline: .red
        }
    }
}

#Preview("Scanning") { ScanningScreen(phase: .weighing) }
#Preview("Result") { ResultScreen(grade: .a, reason: nil) }
#Preview("Disconnected") { DisconnectedScreen() }
#Preview("Dashboard") {
    DashboardScreen(snapshot: StationSnapshot(
        phase: .done,
        lastResult: .init(grade: "B", reason: "Bintik: 11.4% permukaan",
                          weightGrams: 372, volumeCm3: 318,
                          blushPercent: 9, defectPercent: 11.4, gradedAt: .now),
        counts: ["A": 12, "B": 5, "C": 2, "Reject": 1],
        sensors: .allReady,
        updatedAt: .now
    ))
}
