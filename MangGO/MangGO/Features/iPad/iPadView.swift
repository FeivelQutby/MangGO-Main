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
        case dataHarian = "Data Harian"
        case tren = "Tren"
    }

    @Environment(StationSync.self) private var sync
    @State private var tab: Tab = .grading

    @State private var dummyRecords: [MangoRecord] = DummyDataStore.generateDummyRecords()

    private var snapshot: StationSnapshot { sync.snapshot }

    private var finishedGrade: GradeDisplay? {
        sync.isLinked ? snapshot.completedGrade : nil
    }

    private var todayRecords: [MangoRecord] {
        let calendar = Calendar.current
        let today = Date()
        return dummyRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Navigation Bar matching Figma
                ZStack {
                    // Center: Main Tab Picker
                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 420)

                    // Trailing: Sub-preset picker & Debug Toggle
                        Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))

                Divider()

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

        case .dataHarian:
            if dummyRecords.isEmpty {
                EmptyStateView(
                    title: "Belum Ada Data Harian Grading",
                    subtitle: "Mulai batch baru untuk melihat data harian grading",
                    icon: "shippingbox"
                )
            } else {
                RecentScreen(records: dummyRecords)
            }

        case .tren:
            if dummyRecords.isEmpty {
                EmptyStateView(
                    title: "Belum Ada Data Tren Grading",
                    subtitle: "Mulai batch baru untuk melihat data tren grading",
                    icon: "shippingbox"
                )
            } else {
                HistoryScreen(allRecords: dummyRecords)
            }
        }
    }
}

#Preview {
    iPadView().environment(StationSync(role: .display))
}
