//
//  RecentScreen.swift
//  MangGO
//
//  Created from Figma Node 434:535
//

import SwiftUI
import Charts

/// Tampilan "Hasil Terbaru" (Recent Batch / Today's Summary) sesuai desain Figma 434:535.
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
            VStack(alignment: .leading, spacing: 24) {
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

                // Row Top Summary Cards
                HStack(spacing: 16) {
                    // Card 1: Total Buah
                    SummaryTileCard(
                        title: "Total Buah",
                        value: "\(totalCount.formatted()) buah",
                        icon: "🥭",
                        trend: "+ 12,3% dari Batch sebelumnya",
                        isPositive: true
                    )

                    // Card 2: Total Berat
                    SummaryTileCard(
                        title: "Total Berat Mangga",
                        value: String(format: "%.1f kg", totalWeightKg),
                        icon: "⚖️",
                        trend: "+ 9,6% dari Batch sebelumnya",
                        isPositive: true
                    )

                    // Card 3: Rasio Grade
                    GradeRatioCard(
                        gradeAPercent: percentage(for: .a),
                        gradeBPercent: percentage(for: .b),
                        gradeCPercent: percentage(for: .c),
                        rejectPercent: percentage(for: .reject)
                    )
                }

                Text("Hasil Grading Detail")
                    .font(.title2.bold())
                    .padding(.top, 8)

                // Grid 4 Card Hasil Grading (A, B, C, Reject)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    GradeDetailCard(
                        grade: .a,
                        count: count(for: .a),
                        weightKg: weightKg(for: .a),
                        trend: "+ 12,3% dari Batch sebelumnya"
                    )

                    GradeDetailCard(
                        grade: .b,
                        count: count(for: .b),
                        weightKg: weightKg(for: .b),
                        trend: "+ 12,3% dari Batch sebelumnya"
                    )

                    GradeDetailCard(
                        grade: .c,
                        count: count(for: .c),
                        weightKg: weightKg(for: .c),
                        trend: "+ 12,3% dari Batch sebelumnya"
                    )

                    GradeDetailCard(
                        grade: .reject,
                        count: count(for: .reject),
                        weightKg: weightKg(for: .reject),
                        trend: "+ 12,3% dari Batch sebelumnya",
                        actionTitle: "Periksa",
                        onAction: { showingRejectedList = true }
                    )
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingRejectedList) {
            RejectedMangoSheet(records: todayRecords.filter { $0.grade == .reject })
        }
    }
}

// MARK: - Subcomponents

private struct SummaryTileCard: View {
    let title: String
    let value: String
    let icon: String
    let trend: String
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(icon).font(.title2)
                Text(value)
                    .font(.title.bold())
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
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
    }
}

private struct GradeRatioCard: View {
    let gradeAPercent: Double
    let gradeBPercent: Double
    let gradeCPercent: Double
    let rejectPercent: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rasio Grade")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                // Circular Progress Donut Chart
                ZStack {
                    Circle()
                        .stroke(GradeDisplay.reject.color, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: CGFloat((gradeAPercent + gradeBPercent + gradeCPercent) / 100))
                        .stroke(GradeDisplay.c.color, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: CGFloat((gradeAPercent + gradeBPercent) / 100))
                        .stroke(GradeDisplay.b.color, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: CGFloat(gradeAPercent / 100))
                        .stroke(GradeDisplay.a.color, lineWidth: 12)
                }
                .rotationEffect(.degrees(-90))
                .frame(width: 80, height: 80)

                // Legend Grid
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        LegendDot(color: GradeDisplay.a.color)
                        Text("Grade A: ").font(.caption) + Text("\(Int(gradeAPercent))%").font(.caption.bold())
                    }
                    HStack {
                        LegendDot(color: GradeDisplay.b.color)
                        Text("Grade B: ").font(.caption) + Text("\(Int(gradeBPercent))%").font(.caption.bold())
                    }
                    HStack {
                        LegendDot(color: GradeDisplay.c.color)
                        Text("Grade C: ").font(.caption) + Text("\(Int(gradeCPercent))%").font(.caption.bold())
                    }
                    HStack {
                        LegendDot(color: GradeDisplay.reject.color)
                        Text("Reject: ").font(.caption) + Text("\(Int(rejectPercent))%").font(.caption.bold())
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
    }
}

private struct LegendDot: View {
    let color: Color
    var body: some View {
        Circle().fill(color).frame(width: 8, height: 8)
    }
}

private struct GradeDetailCard: View {
    let grade: GradeDisplay
    let count: Int
    let weightKg: Double
    let trend: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Grade \(grade.rawValue)")
                    .font(.headline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(grade.color.opacity(0.2))
                    .foregroundStyle(grade == .c ? Color.black : grade.color)
                    .clipShape(Capsule())

                Spacer()

                if let actionTitle, let onAction {
                    Button(action: onAction) {
                        Text(actionTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor, in: .capsule)
                    }
                }
            }

            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Text("🥭")
                    Text("\(count.formatted()) buah")
                        .font(.title3.bold())
                }
                .padding(10)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 10))

                HStack(spacing: 6) {
                    Text("⚖️")
                    Text(String(format: "%.1f kg", weightKg))
                        .font(.title3.bold())
                }
                .padding(10)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 10))
            }

            HStack(spacing: 4) {
                Image(systemName: "arrow.up.forward")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                Text(trend)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
    }
}

/// Modal Sheet daftar mangga yang ter-reject
struct RejectedMangoSheet: View {
    let records: [MangoRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(records) { record in
                HStack(spacing: 16) {
                    Circle()
                        .fill(GradeDisplay.reject.color)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan ID: \(record.id.uuidString.prefix(8))")
                            .font(.headline)
                        Text(record.rejectionReason ?? "Defek bintik melebihi ambang")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(record.weightGrams)) g")
                            .font(.subheadline.bold())
                        Text(record.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Daftar Mangga Reject (\(records.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    RecentScreen(records: DummyDataStore.generateDummyRecords(days: 1))
}
