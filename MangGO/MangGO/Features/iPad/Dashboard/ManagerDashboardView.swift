//
//  ManagerDashboardView.swift
//  MangGO
//
//  Created for Manda Scope (Manager Dashboard: DATA HARIAN & TREN)
//

import SwiftUI

/// Tab utama Manager Dashboard: DATA HARIAN & TREN (Manda Scope)
struct ManagerDashboardView: View {

    enum DashboardTab: String, CaseIterable, Identifiable {
        case dataHarian = "DATA HARIAN"
        case tren = "TREN"

        var id: String { rawValue }
    }

    let records: [MangoRecord]

    @State private var selectedTab: DashboardTab = .dataHarian
    @State private var trendPreset: DateRangeFilter = .last7
    @State private var forceEmptyState = false

    /// Filter data khusus hari ini
    private var todayRecords: [MangoRecord] {
        let calendar = Calendar.current
        let today = Date()
        return records.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Switcher & Controls Bar
            HStack(spacing: 20) {
                // Primary Tab Switcher (DATA HARIAN vs TREN)
                Picker("Tab", selection: $selectedTab) {
                    ForEach(DashboardTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)

                // Removed trend preset picker from top right.

                Spacer()

                // Debug / Demo Toggle untuk melihat Tampilan Kosong (Empty State)
                Toggle("Simulasi State Kosong", isOn: $forceEmptyState)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .overlay(
                        Text("Kosong: \(forceEmptyState ? "ON" : "OFF")")
                            .font(.caption.bold())
                            .foregroundStyle(forceEmptyState ? .orange : .secondary)
                            .offset(y: 24)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))

            Divider()

            // Tab Content
            Group {
                switch selectedTab {
                case .dataHarian:
                    if forceEmptyState || todayRecords.isEmpty {
                        EmptyStateView(
                            title: "Belum Ada Data Grading Hari Ini",
                            subtitle: "Mangga belum di-grade hari ini. Data harian akan muncul secara otomatis setelah proses grading pertama.",
                            icon: "tray"
                        )
                    } else {
                        RecentScreen(records: todayRecords)
                    }

                case .tren:
                    if forceEmptyState || records.isEmpty {
                        EmptyStateView(
                            title: "Belum Ada Data Tren",
                            subtitle: "Data historis belum tersedia. Terus lakukan grading untuk melihat grafik tren rentang waktu.",
                            icon: "chart.bar"
                        )
                    } else {
                        HistoryScreen(allRecords: records, initialPreset: trendPreset)
                            .id(trendPreset) // Refresh saat preset berubah
                    }
                }
            }
        }
    }
}

#Preview("Data Harian Active") {
    ManagerDashboardView(records: DummyDataStore.generateDummyRecords())
}
