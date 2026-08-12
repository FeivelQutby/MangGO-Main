//
//  StationSimulator.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//


#if DEBUG

import SwiftUI

struct SimulatorPanel: View {

    @Environment(StationSync.self) private var sync
    @State private var counts: [String: Int] = [:]
    @State private var running = false

    var body: some View {
        VStack(spacing: 20) {
            Label(sync.isLinked ? "iPad tersambung" : "Mencari iPad",
                  systemImage: sync.isLinked ? "ipad" : "ipad.gen2.slash")
                .font(.headline)
                .foregroundStyle(sync.isLinked ? .green : .orange)

            HStack(spacing: 12) {
                ForEach(GradeDisplay.allCases) { grade in
                    Button(grade.rawValue) { Task { await run(grade) } }
                        .buttonStyle(.borderedProminent)
                        .tint(grade.color)
                }
            }
            .disabled(running)

            Button("Reset ke Idle") { emit(.idle) }
                .buttonStyle(.bordered)
        }
        .padding(24)
        .onAppear { emit(.idle) }
    }

    private func run(_ grade: GradeDisplay) async {
        running = true
        defer { running = false }

        for phase in [StationSnapshot.Phase.scanningFront, .flipping, .weighing, .scanningBack] {
            emit(phase)
            try? await Task.sleep(for: .seconds(1.2))
        }

        counts[grade.rawValue, default: 0] += 1
        var snap = snapshot(.done)
        snap.lastResult = .init(
            grade: grade.rawValue,
            reason: grade == .a ? nil : "Bintik melebihi ambang batas",
            weightGrams: .random(in: 300...500),
            volumeCm3: .random(in: 250...520),
            blushPercent: .random(in: 2...38),
            defectPercent: .random(in: 0...25),
            gradedAt: .now
        )
        sync.publish(snap)
    }

    private func emit(_ phase: StationSnapshot.Phase) {
        sync.publish(snapshot(phase))
    }

    private func snapshot(_ phase: StationSnapshot.Phase) -> StationSnapshot {
        StationSnapshot(phase: phase, lastResult: sync.snapshot.lastResult,
                        counts: counts, sensors: .allReady, updatedAt: .now)
    }
}

#endif
