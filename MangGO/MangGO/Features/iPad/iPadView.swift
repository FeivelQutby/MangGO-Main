//
//  iPadView.swift
//  MangGO
//
//  Created by Feivel Qutby on 07/08/26.
//

import SwiftUI

struct iPadView: View {

    enum Tab: String, CaseIterable { case grading = "Grading", dashboard = "Dashboard" }

    @Environment(StationSync.self) private var sync
    @State private var tab: Tab = .grading

    private var snapshot: StationSnapshot { sync.snapshot }

    private var finishedGrade: GradeDisplay? {
        guard sync.isLinked, snapshot.phase == .done,
              let raw = snapshot.lastResult?.grade else { return nil }
        return GradeDisplay(rawValue: raw)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 340)
                .padding(.vertical, 20)

                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Layar hasil hanya menutupi tab Grading. Di tab Dashboard operator
            // sedang membaca angka; menimpanya dengan warna penuh layar tiap
            // buah selesai membuat dashboard tidak terbaca.
            if tab == .grading, let grade = finishedGrade,
               let result = snapshot.lastResult {
                ResultScreen(grade: grade, reason: result.reason)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: snapshot.phase)
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .dashboard:
            DashboardScreen(snapshot: snapshot)
        case .grading:
            // Link putus lebih penting daripada state terakhir: angka basi di
            // lantai pabrik lebih berbahaya daripada layar kosong.
            if !sync.isLinked {
                DisconnectedScreen(message: sync.lastError)
            } else if snapshot.phase.isWorking {
                ScanningScreen(phase: snapshot.phase)
            } else {
                IdleScreen(sensors: snapshot.sensors)
            }
        }
    }
}

#Preview {
    iPadView().environment(StationSync(role: .display))
}
