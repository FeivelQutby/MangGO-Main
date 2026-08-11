//
//  RecentScreen.swift
//  MangGO
//
//  Created from Figma Node 434:535 & 2nd Iteration Specs
//

import SwiftUI
import Charts

/// Tampilan "Hasil Terbaru" (Recent Batch / Today's Summary)
/// Iterasi 2: Layout 2 Kolom (Kiri: Stack Cards Total & Reject | Kanan: 2 Bar Charts + Tabel 4 Kolom)
struct RecentScreen: View {

    let records: [MangoRecord]

    @State private var showingRejectedList = false

    /// Filter data khusus hari ini (atau batch terbaru)
    private var todayRecords: [MangoRecord] {
        let calendar = Calendar.current
        let today = Date()
        let filtered = records.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        return filtered.isEmpty ? records : filtered
    }

    private var totalCount: Int {
        todayRecords.count
    }

    private var totalWeightKg: Double {
        todayRecords.reduce(0.0) { $0 + $1.weightGrams } / 1000.0
    }

    private func count(for grade: GradeDisplay) -> Int {
        todayRecords.filter { $0.grade == grade }.count
    }

    private func weightKg(for grade: GradeDisplay) -> Double {
        todayRecords.filter { $0.grade == grade }.reduce(0.0) { $0 + $1.weightGrams } / 1000.0
    }

    private func percentage(for grade: GradeDisplay) -> Double {
        guard totalCount > 0 else { return 0 }
        return (Double(count(for: grade)) / Double(totalCount)) * 100.0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Tanggal
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hasil Terbaru (Batch Hari Ini)")
                            .font(.title.bold())
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Split Layout 2 Kolom
                HStack(alignment: .top, spacing: 24) {
                    // ==========================================
                    // KOLOM KIRI: 3 Card Stacked Vertikal (Width: 320)
                    // ==========================================
                    VStack(spacing: 16) {
                        // Card 1: Total Buah
                        MetricSummaryCard(
                            title: "Total Buah",
                            value: "\(totalCount.formatted()) buah",
                            icon: "🥭",
                            trend: "+ 12,3% dari Batch sebelumnya",
                            isPositive: true
                        )

                        // Card 2: Total Berat
                        MetricSummaryCard(
                            title: "Total Berat Mangga",
                            value: String(format: "%.1f kg", totalWeightKg),
                            icon: "⚖️",
                            trend: "+ 9,6% dari Batch sebelumnya",
                            isPositive: true
                        )

                        // Card 3: Mangga Ter-Reject + Tombol "Periksa"
                        RejectedSummaryCard(
                            count: count(for: .reject),
                            percentage: percentage(for: .reject),
                            onPeriksa: { showingRejectedList = true }
                        )
                    }
                    .frame(width: 320)

                    // ==========================================
                    // KOLOM KANAN: 2 Bar Charts + Tabel 4 Kolom
                    // ==========================================
                    VStack(spacing: 20) {
                        // Top Section: 2 Bar Charts Berdampingan
                        HStack(spacing: 16) {
                            // Chart 1: Jumlah per Grade
                            ChartContainerCard(title: "Jumlah per Grade") {
                                Chart {
                                    ForEach(GradeDisplay.allCases) { grade in
                                        BarMark(
                                            x: .value("Grade", "Grade \(grade.rawValue)"),
                                            y: .value("Jumlah", count(for: grade))
                                        )
                                        .foregroundStyle(grade.color)
                                    }
                                }
                                .chartYAxisLabel("Buah")
                            }

                            // Chart 2: Total Berat per Grade
                            ChartContainerCard(title: "Total Berat per Grade") {
                                Chart {
                                    ForEach(GradeDisplay.allCases) { grade in
                                        BarMark(
                                            x: .value("Grade", "Grade \(grade.rawValue)"),
                                            y: .value("Berat", weightKg(for: grade))
                                        )
                                        .foregroundStyle(grade.color)
                                    }
                                }
                                .chartYAxisLabel("kg")
                            }
                        }

                        // Bottom Section: Tabel Ringkasan 4 Kolom
                        GradeSummaryTableView(
                            records: todayRecords,
                            totalCount: totalCount,
                            countForGrade: { count(for: $0) },
                            weightForGrade: { weightKg(for: $0) },
                            percentageForGrade: { percentage(for: $0) }
                        )
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingRejectedList) {
            RejectedMangoListView(
                rejectedRecords: todayRecords.filter { $0.grade == .reject }
            )
        }
    }
}

// MARK: - Subcomponents

private struct MetricSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let trend: String
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(icon).font(.title2)
                Text(value)
                    .font(.title2.bold())
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.forward" : "arrow.down.forward")
                    .font(.caption.bold())
                    .foregroundStyle(isPositive ? .green : .red)
                Text(trend)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isPositive ? Color.green.opacity(0.12) : Color.red.opacity(0.12), in: .capsule)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
    }
}

private struct RejectedSummaryCard: View {
    let count: Int
    let percentage: Double
    let onPeriksa: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("🚫").font(.title2)
                Text("\(count.formatted()) buah")
                    .font(.title2.bold())
                    .foregroundStyle(GradeDisplay.reject.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Mangga Ter-Reject Hari Ini")
                    .font(.subheadline.bold())
                Text("Rasio Reject: \(String(format: "%.1f%%", percentage)) dari total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onPeriksa) {
                HStack {
                    Text("Periksa")
                        .font(.subheadline.bold())
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(GradeDisplay.reject.color, in: .capsule)
                .foregroundStyle(.white)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
    }
}

private struct ChartContainerCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.bold())
            content()
                .frame(height: 180)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
    }
}

private struct GradeSummaryTableView: View {
    let records: [MangoRecord]
    let totalCount: Int
    let countForGrade: (GradeDisplay) -> Int
    let weightForGrade: (GradeDisplay) -> Double
    let percentageForGrade: (GradeDisplay) -> Double

    var body: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack {
                Text("Grade")
                    .font(.subheadline.bold())
                    .frame(width: 110, alignment: .leading)
                Text("Jumlah")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("Berat")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("Rasio")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))

            Divider()

            // Rows for Grade A, B, C, Reject
            ForEach(GradeDisplay.allCases) { grade in
                HStack {
                    Text("Grade \(grade.rawValue)")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(grade.color.opacity(0.2))
                        .foregroundStyle(grade == .c ? Color.black : grade.color)
                        .clipShape(Capsule())
                        .frame(width: 110, alignment: .leading)

                    Text("\(countForGrade(grade).formatted()) buah")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(String(format: "%.1f kg", weightForGrade(grade)))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(String(format: "%.1f%%", percentageForGrade(grade)))
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if grade != GradeDisplay.allCases.last {
                    Divider()
                }
            }
        }
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    RecentScreen(records: DummyDataStore.generateDummyRecords(days: 1))
}
