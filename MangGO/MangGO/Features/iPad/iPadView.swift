//
//  iPadView.swift
//  MangGO
//
//  Created by Feivel Qutby on 07/08/26.
//

import SwiftUI

/// Shell layar iPad: hanya mengurus pemilihan tab dan overlay hasil.
/// Isi tiap tab ada di `Grading/GradingScreen.swift` dan
/// `Dashboard/DashboardScreen.swift`.
struct iPadView: View {

    enum Tab: String, CaseIterable {
        case grading = "Grading"
        case recent = "Hasil Terbaru"
        case history = "Riwayat"
    }

    @Environment(StationSync.self) private var sync
    @State private var tab: Tab = .grading
    @State private var dummyRecords: [MangoRecord] = DummyDataStore.generateDummyRecords(days: 30)

    private var snapshot: StationSnapshot { sync.snapshot }

    private var finishedGrade: GradeDisplay? {
        sync.isLinked ? snapshot.completedGrade : nil
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 480)
                .padding(.vertical, 16)

                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Layar hasil hanya menutupi tab Grading.
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
        case .grading:
            GradingScreen(snapshot: snapshot,
                          isLinked: sync.isLinked,
                          connectionError: sync.lastError)
        case .recent:
            RecentScreen(records: dummyRecords)
        case .history:
            HistoryScreen(allRecords: dummyRecords)
        }
    }
}

#Preview {
    iPadView().environment(StationSync(role: .display))
}
