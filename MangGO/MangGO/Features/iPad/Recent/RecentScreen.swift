import SwiftUI
import Charts

/// Tampilan "Hasil Terbaru" (Recent Batch / Today's Summary)
/// Iterasi 2: Layout 2 Kolom (Kiri: Stack Cards Total & Reject | Kanan: 2 Bar Charts + Tabel 4 Kolom)
struct RecentScreen: View {

    let records: [MangoRecord]

    @State private var showingRejectedList = false
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false

    /// Filter data berdasarkan selectedDate
    private var todayRecords: [MangoRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
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
        VStack(alignment: .leading, spacing: 0) {
            // Header Tanggal (Fixed Top Header - Stay Freeze!)
            Button(action: { showingDatePicker = true }) {
                HStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color(red: 114/255, green: 114/255, blue: 114/255))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 228/255, green: 228/255, blue: 229/255))

                    HStack(spacing: 10) {
                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 20))
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .popover(isPresented: $showingDatePicker) {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .frame(width: 320, height: 340)
                    .presentationCompactAdaptation(.popover)
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 242/255, green: 242/255, blue: 247/255))

            // Scrollable Content Body
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    if todayRecords.isEmpty {
                        EmptyStateView(
                            title: "Belum Ada Data Harian Grading",
                            subtitle: "Mulai batch baru untuk melihat data harian grading",
                            icon: "shippingbox"
                        )
                        .frame(maxWidth: .infinity, minHeight: 450)
                    } else {
                        // Split Layout 2 Kolom
                        HStack(alignment: .top, spacing: 32) {
                            // ==========================================
                            // KOLOM KIRI: Overview Total
                            // ==========================================
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Overview Total")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Color(red: 26/255, green: 26/255, blue: 26/255))

                                // Card 1: Total Buah
                                MetricSummaryCard(
                                    title: "total mangga diperiksa",
                                    value: "\(totalCount.formatted()) buah",
                                    icon: "🥭"
                                )

                                // Card 2: Total Berat
                                MetricSummaryCard(
                                    title: "total berat mangga",
                                    value: String(format: "%.1f kg", totalWeightKg),
                                    icon: "⚖️"
                                )

                                // Card 3: Mangga Ter-Reject + Tombol "Periksa"
                                RejectedSummaryCard(
                                    count: count(for: .reject),
                                    onPeriksa: { showingRejectedList = true }
                                )
                            }
                            .frame(width: 360)

                            // ==========================================
                            // KOLOM KANAN: Hasil Grading Harian
                            // ==========================================
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Hasil Grading Harian")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Color(red: 26/255, green: 26/255, blue: 26/255))

                                // Top Section: 2 Bar Charts Berdampingan
                                HStack(spacing: 16) {
                                    // Chart 1: Kuantitas (buah)
                                    ChartContainerCard(title: "Kuantitas (buah)") {
                                        Chart {
                                            ForEach(GradeDisplay.allCases) { grade in
                                                let val = count(for: grade)
                                                BarMark(
                                                    x: .value("Grade", grade == .reject ? "Reject" : "Grade \(grade.rawValue)"),
                                                    y: .value("Jumlah", val),
                                                    width: .ratio(0.5)
                                                )
                                                .foregroundStyle(grade.color)
                                                .annotation(position: .top) {
                                                    Text("\(val)")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(Color(red: 114/255, green: 114/255, blue: 114/255))
                                                }
                                            }
                                        }
                                        .chartYAxis {
                                            AxisMarks(position: .leading)
                                        }
                                    }

                                    // Chart 2: Berat (kg)
                                    ChartContainerCard(title: "Berat (kg)") {
                                        Chart {
                                            ForEach(GradeDisplay.allCases) { grade in
                                                let val = weightKg(for: grade)
                                                BarMark(
                                                    x: .value("Grade", grade == .reject ? "Reject" : "Grade \(grade.rawValue)"),
                                                    y: .value("Berat", val),
                                                    width: .ratio(0.5)
                                                )
                                                .foregroundStyle(grade.color)
                                                .annotation(position: .top) {
                                                    Text(String(format: "%.1f", val))
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(Color(red: 114/255, green: 114/255, blue: 114/255))
                                                }
                                            }
                                        }
                                        .chartYAxis {
                                            AxisMarks(position: .leading)
                                        }
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
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
        .fullScreenCover(isPresented: $showingRejectedList) {
            // Data Harian sudah dipersempit ke satu tanggal, jadi tidak ada
            // `dateContext` — filter tanggal per kelompok hanya relevan di Tren.
            RejectedMangoListView(
                rejectedRecords: todayRecords.filter { $0.grade == .reject },
                contextTitle: "Data Harian"
            )
        }
    }
}

// MARK: - Subcomponents

private struct MetricSummaryCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(icon).font(.system(size: 32))
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
            }
            Text(title)
                .font(.system(size: 18))
                .foregroundStyle(Color(red: 114/255, green: 114/255, blue: 114/255))
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: .rect(cornerRadius: 24))
    }
}

private struct RejectedSummaryCard: View {
    let count: Int
    let onPeriksa: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text("🗑️").font(.system(size: 32))
                    Text("\(count.formatted()) buah")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.black)
                }
                Text("mangga reject")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 114/255, green: 114/255, blue: 114/255))
            }

            Button(action: onPeriksa) {
                Text("Periksa Detail")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue, in: .capsule)
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: .rect(cornerRadius: 24))
    }
}

private struct ChartContainerCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(red: 26/255, green: 26/255, blue: 26/255))
            content()
                .frame(height: 200)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: .rect(cornerRadius: 24))
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
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Kuantitas (buah)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Berat Total (kg)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Rasio")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 142/255, green: 142/255, blue: 147/255)) // exact gray header from Figma

            // Rows for Grade A, B, C, Reject
            ForEach(Array(GradeDisplay.allCases.enumerated()), id: \.element) { index, grade in
                HStack {
                    Text(grade == .reject ? "Reject" : grade.rawValue)
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(countForGrade(grade).formatted())
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(String(format: "%.1f", weightForGrade(grade))) // weight column in kg
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(String(format: "%.0f%%", percentageForGrade(grade)))
                        .font(.system(size: 20))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(index % 2 == 1 ? Color(red: 116/255, green: 116/255, blue: 128/255).opacity(0.08) : Color.white)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    RecentScreen(records: DummyDataStore.generateDummyRecords())
}
