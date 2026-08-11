//
//  HistoryScreen.swift
//  MangGO
//

import SwiftUI
import Charts

/// Filter rentang waktu untuk Riwayat
enum DateRangeFilter: String, CaseIterable, Identifiable {
    case today = "Hari Esok"
    case last7 = "7 Hari Terakhir"
    case last14 = "14 Hari Terakhir"
    case last30 = "30 Hari Terakhir"
    case custom = "Kustom"

    var id: String { rawValue }
}

/// Layar Riwayat (History Screen) dengan filter rentang waktu & grafik tren.
struct HistoryScreen: View {

    let allRecords: [MangoRecord]

    @State private var selectedFilter: DateRangeFilter = .last7
    @State private var selectedGradeFilter: GradeDisplay? = nil
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var endDate: Date = Date()
    @State private var searchText = ""

    /// Records yang disaring berdasarkan tanggal
    private var dateFilteredRecords: [MangoRecord] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .today:
            return allRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
        case .last7:
            guard let from = calendar.date(byAdding: .day, value: -7, to: now) else { return allRecords }
            return allRecords.filter { $0.timestamp >= from }
        case .last14:
            guard let from = calendar.date(byAdding: .day, value: -14, to: now) else { return allRecords }
            return allRecords.filter { $0.timestamp >= from }
        case .last30:
            guard let from = calendar.date(byAdding: .day, value: -30, to: now) else { return allRecords }
            return allRecords.filter { $0.timestamp >= from }
        case .custom:
            let start = calendar.startOfDay(for: startDate)
            guard let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) else {
                return allRecords
            }
            return allRecords.filter { $0.timestamp >= start && $0.timestamp <= end }
        }
    }

    /// Records final yang juga disaring berdasarkan grade & search query
    private var finalRecords: [MangoRecord] {
        var result = dateFilteredRecords

        if let selectedGradeFilter {
            result = result.filter { $0.grade == selectedGradeFilter }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.id.uuidString.localizedCaseInsensitiveContains(searchText) ||
                ($0.rejectionReason?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result
    }

    // MARK: - Metrics Calculations

    private var totalCount: Int { dateFilteredRecords.count }

    private var totalWeightKg: Double {
        dateFilteredRecords.reduce(0.0) { $0 + $1.weightGrams } / 1000.0
    }

    private var avgWeightGrams: Double {
        guard totalCount > 0 else { return 0 }
        return dateFilteredRecords.reduce(0.0) { $0 + $1.weightGrams } / Double(totalCount)
    }

    private var passRatePercent: Double {
        guard totalCount > 0 else { return 0 }
        let passed = dateFilteredRecords.filter { $0.grade != .reject }.count
        return (Double(passed) / Double(totalCount)) * 100.0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header & Filter Bar
                VStack(alignment: .leading, spacing: 16) {
                    Text("Riwayat & Tren Grading")
                        .font(.title.bold())

                    HStack(spacing: 12) {
                        // Segmented Control Rentang Waktu
                        Picker("Rentang Waktu", selection: $selectedFilter) {
                            ForEach(DateRangeFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 550)

                        Spacer()

                        if selectedFilter == .custom {
                            HStack(spacing: 8) {
                                DatePicker("Mulai", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                Text("–").foregroundStyle(.secondary)
                                DatePicker("Sampai", selection: $endDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 8))
                        }
                    }
                }

                // Summary KPI Cards
                HStack(spacing: 16) {
                    KpiTile(title: "Total Buah", value: "\(totalCount.formatted())", unit: "buah", icon: "🥭")
                    KpiTile(title: "Total Berat", value: String(format: "%.1f", totalWeightKg), unit: "kg", icon: "⚖️")
                    KpiTile(title: "Rata-rata Berat", value: String(format: "%.0f", avgWeightGrams), unit: "gram", icon: "📊")
                    KpiTile(title: "Pass Rate", value: String(format: "%.1f", passRatePercent), unit: "%", icon: "✅",
                            highlightColor: passRatePercent >= 85 ? .green : .orange)
                }

                // Grafik Tren Volume Grading per Hari
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Grafik Tren Hasil Grading")
                            .font(.title2.bold())
                        Spacer()
                        Text("\(dateFilteredRecords.count) sampel terdata")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Chart {
                        ForEach(dailySummaries) { summary in
                            BarMark(
                                x: .value("Tanggal", summary.dateLabel),
                                y: .value("Jumlah", summary.count)
                            )
                            .foregroundStyle(by: .value("Grade", summary.grade.rawValue))
                        }
                    }
                    .chartForegroundStyleScale([
                        "A": GradeDisplay.a.color,
                        "B": GradeDisplay.b.color,
                        "C": GradeDisplay.c.color,
                        "Reject": GradeDisplay.reject.color
                    ])
                    .frame(height: 280)
                    .padding(16)
                    .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
                }

                // Log Detail Riwayat
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Daftar Riwayat Scan")
                            .font(.title2.bold())

                        Spacer()

                        // Filter Grade
                        HStack(spacing: 8) {
                            FilterChip(title: "Semua", isSelected: selectedGradeFilter == nil) {
                                selectedGradeFilter = nil
                            }
                            ForEach(GradeDisplay.allCases) { grade in
                                FilterChip(title: grade.rawValue, isSelected: selectedGradeFilter == grade, color: grade.color) {
                                    selectedGradeFilter = grade
                                }
                            }
                        }
                    }

                    // Log Table
                    LazyVStack(spacing: 10) {
                        ForEach(finalRecords.prefix(50)) { record in
                            HistoryRecordRow(record: record)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Cari ID scan atau alasan reject...")
    }

    // Helper data summary untuk SwiftCharts
    private var dailySummaries: [DailyGradeSummary] {
        let calendar = Calendar.current
        var map: [String: [GradeDisplay: Int]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"

        for record in dateFilteredRecords {
            let dayKey = formatter.string(from: record.timestamp)
            map[dayKey, default: [:]][record.grade, default: 0] += 1
        }

        var summaries: [DailyGradeSummary] = []
        for (dateLabel, gradeCounts) in map {
            for (grade, count) in gradeCounts {
                summaries.append(DailyGradeSummary(dateLabel: dateLabel, grade: grade, count: count))
            }
        }
        return summaries.sorted(by: { $0.dateLabel < $1.dateLabel })
    }
}

// MARK: - Helper Views & Models

private struct DailyGradeSummary: Identifiable {
    var id: String { "\(dateLabel)-\(grade.rawValue)" }
    let dateLabel: String
    let grade: GradeDisplay
    let count: Int
}

private struct KpiTile: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    var highlightColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(icon).font(.title3)
                Spacer()
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title.bold())
                    .foregroundStyle(highlightColor ?? .primary)
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
    }
}

private struct HistoryRecordRow: View {
    let record: MangoRecord

    var body: some View {
        HStack(spacing: 16) {
            Text("Grade \(record.grade.rawValue)")
                .font(.subheadline.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(record.grade.color.opacity(0.2))
                .foregroundStyle(record.grade == .c ? Color.black : record.grade.color)
                .clipShape(Capsule())
                .frame(width: 90)

            VStack(alignment: .leading, spacing: 4) {
                Text("ID: \(record.id.uuidString.prefix(8))")
                    .font(.headline)
                Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 24) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(record.weightGrams)) g")
                        .font(.subheadline.bold())
                    Text("Berat")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(record.volumeCm3)) cm³")
                        .font(.subheadline.bold())
                    Text("Volume")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f%%", record.defectPercent))
                        .font(.subheadline.bold())
                        .foregroundStyle(record.defectPercent > 15 ? .red : .primary)
                    Text("Bintik Defek")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 14))
    }
}

#Preview {
    HistoryScreen(allRecords: DummyDataStore.generateDummyRecords(days: 30))
}
