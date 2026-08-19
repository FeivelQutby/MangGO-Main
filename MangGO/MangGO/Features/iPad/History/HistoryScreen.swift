//
//  HistoryScreen.swift
//  MangGO
//
//  Created from Figma Nodes 551:9204, 551:9287, 551:9367 (Tren 7 Hari, 30 Hari, 3 Bulan)
//

import SwiftUI
import Charts
import Combine

/// Filter rentang waktu untuk Riwayat
enum DateRangeFilter: String, CaseIterable, Identifiable {
    case last7 = "7 Hari"
    case last30 = "30 Hari"
    case last90 = "90 Hari"

    var id: String { rawValue }
}

/// Rentang waktu Tren yang sedang aktif, lengkap dengan pengelompokannya.
///
/// Dibuat supaya layar turunan Tren (mis. "Log Mangga Reject") memakai rentang
/// dan kelompok tanggal yang **sama persis** dengan bar chart di layar Tren,
/// bukan menghitung ulang sendiri. Selama keduanya membaca dari sini, filter di
/// layar awal otomatis ikut terbawa dan tidak ada dua sumber kebenaran yang bisa
/// berbeda diam-diam.
struct TrendDateContext: Equatable {

    var filter: DateRangeFilter
    var anchorDate: Date

    /// Satu kolom pada bar chart Tren, sekaligus satu baris pada daftar filter
    /// tanggal di layar Log Mangga Reject.
    struct Bucket: Identifiable, Hashable {
        let index: Int
        let label: String
        let start: Date
        let end: Date

        var id: Int { index }
    }

    // MARK: Rentang

    var startDate: Date {
        let calendar = Calendar.current
        switch filter {
        case .last7:
            return calendar.date(byAdding: .day, value: -6, to: anchorDate) ?? anchorDate
        case .last30:
            return calendar.date(byAdding: .day, value: -29, to: anchorDate) ?? anchorDate
        case .last90:
            return calendar.date(byAdding: .day, value: -89, to: anchorDate) ?? anchorDate
        }
    }

    var endDate: Date { anchorDate }

    // MARK: Pengelompokan

    /// Lebar tiap kelompok dalam hari. Angka-angka ini yang dulu tersebar di
    /// `stackedChartData` sebagai pembagi (`/ 6`, `/ 15`).
    var bucketSpanDays: Int {
        switch filter {
        case .last7: 1
        case .last30: 6
        case .last90: 15
        }
    }

    var bucketCount: Int {
        switch filter {
        case .last7: 7
        case .last30: 5
        case .last90: 6
        }
    }

    private var gridStart: Date {
        Calendar.current.startOfDay(for: startDate)
    }

    var buckets: [Bucket] {
        let calendar = Calendar.current
        let start = gridStart

        return (0..<bucketCount).compactMap { index -> Bucket? in
            guard let bucketStart = calendar.date(
                byAdding: .day,
                value: index * bucketSpanDays,
                to: start
            ),
            let bucketEnd = calendar.date(
                byAdding: .day,
                value: bucketSpanDays - 1,
                to: bucketStart
            ) else { return nil }

            return Bucket(
                index: index,
                label: Self.label(start: bucketStart, end: bucketEnd, spanDays: bucketSpanDays),
                start: bucketStart,
                end: bucketEnd
            )
        }
    }

    /// Kelompok tempat sebuah tanggal jatuh. Di-clamp ke rentang yang ada supaya
    /// catatan tepat di tepi tidak pernah keluar dari indeks kelompok.
    func bucketIndex(for date: Date) -> Int {
        let calendar = Calendar.current
        let dayDiff = calendar.dateComponents(
            [.day],
            from: gridStart,
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        return max(0, min(bucketCount - 1, dayDiff / bucketSpanDays))
    }

    /// Label kelompok: satu tanggal untuk 7 hari, rentang untuk 30 hari & 3 bulan.
    private static func label(start: Date, end: Date, spanDays: Int) -> String {
        let dayMonth = DateFormatter()
        dayMonth.dateFormat = "d MMM"

        guard spanDays > 1 else { return dayMonth.string(from: start) }

        let calendar = Calendar.current
        if calendar.component(.month, from: start) == calendar.component(.month, from: end) {
            let day = DateFormatter()
            day.dateFormat = "d"
            return "\(day.string(from: start))-\(dayMonth.string(from: end))"
        }

        return "\(dayMonth.string(from: start)) - \(dayMonth.string(from: end))"
    }
}

/// Layar Riwayat & Tren (History & Trend Screen) sesuai Figma Spec
struct HistoryScreen: View {

    let allRecords: [MangoRecord]

    @State private var selectedFilter: DateRangeFilter = .last7
    @State private var selectedMetric: TrendMetric = .quantity
    @State private var showingRejectedList = false
    @State private var showingRangePicker = false
    @State private var customAnchorDate: Date? = nil

    enum TrendMetric: String, CaseIterable, Identifiable {
        case quantity = "Kuantitas (buah)"
        case weight = "Berat (kg)"

        var id: String { rawValue }
    }

    /// Initializer opsional untuk set preset langsung dari parent
    init(allRecords: [MangoRecord], initialPreset: DateRangeFilter = .last7) {
        self.allRecords = allRecords
        _selectedFilter = State(initialValue: initialPreset)
    }

    private var currentAnchorDate: Date {
        customAnchorDate ?? allRecords.map(\.timestamp).max() ?? Date()
    }

    /// Sumber tunggal rentang + pengelompokan tanggal. Dipakai layar ini untuk
    /// bar chart, dan diteruskan apa adanya ke `RejectedMangoListView` supaya
    /// filter yang dipilih di sini ikut terbawa ke Log Mangga Reject.
    private var dateContext: TrendDateContext {
        TrendDateContext(filter: selectedFilter, anchorDate: currentAnchorDate)
    }

    /// Start date calculation
    private var startDate: Date { dateContext.startDate }

    /// End date calculation
    private var endDate: Date { dateContext.endDate }

    private var maxDate: Date {
        allRecords.map(\.timestamp).max() ?? Date()
    }

    /// Subtitle string
    private var dateRangeSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, yyyy"
        formatter.locale = Locale(identifier: "id_ID")
        return "Data tren pada tanggal \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /// Records yang disaring berdasarkan tanggal
    private var dateFilteredRecords: [MangoRecord] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return allRecords.filter { $0.timestamp >= start && $0.timestamp <= end }
    }

    // MARK: - Metrics Calculations

    private var totalCount: Int { dateFilteredRecords.count }

    private var totalWeightKg: Double {
        dateFilteredRecords.reduce(0.0) { $0 + $1.weightGrams } / 1000.0
    }

    private func count(for grade: GradeDisplay) -> Int {
        dateFilteredRecords.filter { $0.grade == grade }.count
    }

    private func weightKg(for grade: GradeDisplay) -> Double {
        dateFilteredRecords.filter { $0.grade == grade }.reduce(0.0) { $0 + $1.weightGrams } / 1000.0
    }

    private func percentage(for grade: GradeDisplay) -> Double {
        guard totalCount > 0 else { return 0 }
        return (Double(count(for: grade)) / Double(totalCount)) * 100.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Selector Tanggal (Fixed Top Header - Stay Freeze!)
            VStack(alignment: .leading, spacing: 6) {
                Button(action: { showingRangePicker = true }) {
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
                            Text("Tren \(selectedFilter.rawValue)")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingRangePicker) {
                    DateRangePickerPopover(
                        selectedFilter: $selectedFilter,
                        anchorDate: $customAnchorDate,
                        isPresented: $showingRangePicker,
                        defaultAnchor: allRecords.map(\.timestamp).max() ?? Date()
                    )
                    .presentationCompactAdaptation(.popover)
                }

                Text(dateRangeSubtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 114/255, green: 114/255, blue: 114/255))
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 242/255, green: 242/255, blue: 247/255))

            // Scrollable Content Body (Hasil Grading & Akumulasi)
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    if dateFilteredRecords.isEmpty {
                        EmptyStateView(
                            title: "Belum Ada Data Tren Grading",
                            subtitle: "Mulai batch baru untuk melihat data tren grading",
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

                                // Card 1: Total Buah + Trend Badge
                                TrendMetricSummaryCard(
                                    title: "total mangga diperiksa",
                                    value: "\(totalCount.formatted()) buah",
                                    icon: "🥭"
                                )

                                // Card 2: Total Berat + Trend Badge
                                TrendMetricSummaryCard(
                                    title: "total berat mangga",
                                    value: String(format: "%.1f kg", totalWeightKg),
                                    icon: "⚖️"
                                )

                                // Card 3: Mangga Ter-Reject + Tombol "Periksa Detail"
                                TrendRejectedSummaryCard(
                                    count: count(for: .reject),
                                    onPeriksa: { showingRejectedList = true }
                                )
                            }
                            .frame(width: 360)

                            // ==========================================
                            // KOLOM KANAN: Hasil Grading & Akumulasi
                            // ==========================================
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Hasil Grading")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Color(red: 26/255, green: 26/255, blue: 26/255))

                                // Card 1: Stacked Bar Chart with Metric Segmented Control
                                VStack(spacing: 20) {
                                    Picker("", selection: $selectedMetric) {
                                        ForEach(TrendMetric.allCases) { metric in
                                            Text(metric.rawValue).tag(metric)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 320)

                                    Chart {
                                        // Bar chart elements stacked
                                        ForEach(stackedChartData) { item in
                                            BarMark(
                                                x: .value("Tanggal", item.dateLabel),
                                                y: .value("Nilai", item.value),
                                                width: .ratio(0.4)
                                            )
                                            .foregroundStyle(by: .value("Grade", item.grade.rawValue))
                                        }
                                        
                                        // Line chart for Reject overlay
                                        ForEach(stackedChartData.filter { $0.grade == .reject }) { item in
                                            LineMark(
                                                x: .value("Tanggal", item.dateLabel),
                                                y: .value("Reject Line", item.value)
                                            )
                                            .foregroundStyle(Color.red)
                                            .lineStyle(StrokeStyle(lineWidth: 3))
                                            .symbol {
                                                Circle()
                                                    .fill(Color.red)
                                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                                                    .frame(width: 8, height: 8)
                                            }
                                        }
                                    }
                                    .chartForegroundStyleScale(
                                        domain: [GradeDisplay.reject.rawValue, GradeDisplay.c.rawValue, GradeDisplay.b.rawValue, GradeDisplay.a.rawValue],
                                        range: [GradeDisplay.reject.color, GradeDisplay.c.color, GradeDisplay.b.color, GradeDisplay.a.color]
                                    )
                                    .chartLegend(.hidden)
                                    .chartYAxis {
                                        AxisMarks(position: .leading)
                                    }
                                    .frame(height: 240)
                                    
                                    // Custom Legend
                                    HStack(spacing: 24) {
                                        ForEach([GradeDisplay.a, GradeDisplay.b, GradeDisplay.c, GradeDisplay.reject], id: \.self) { grade in
                                            HStack(spacing: 8) {
                                                Circle()
                                                    .fill(grade.color)
                                                    .frame(width: 12, height: 12)
                                                Text(grade == .reject ? "Reject" : "Grade \(grade.rawValue)")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity)
                                .background(Color.white, in: .rect(cornerRadius: 24))

                                // Card 2: Tabel Akumulasi (Akumulasi 7 Hari / 30 Hari / 3 Bulan)
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Akumulasi \(selectedFilter.rawValue)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(Color(red: 26/255, green: 26/255, blue: 26/255))

                                    GradeSummaryTableView(
                                        records: dateFilteredRecords,
                                        totalCount: totalCount,
                                        countForGrade: { count(for: $0) },
                                        weightForGrade: { weightKg(for: $0) },
                                        percentageForGrade: { percentage(for: $0) }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
        .fullScreenCover(isPresented: $showingRejectedList) {
            // `dateContext` diteruskan supaya layar Log Mangga Reject memakai
            // rentang dan kelompok tanggal yang sama dengan yang dipilih di sini,
            // bukan membuat filter baru yang berdiri sendiri.
            RejectedMangoListView(
                rejectedRecords: dateFilteredRecords.filter { $0.grade == .reject },
                contextTitle: "Tren \(selectedFilter.rawValue)",
                dateContext: dateContext
            )
        }
    }

    // MARK: - Stacked Chart Data Aggregation

    private struct StackedChartItem: Identifiable {
        var id: String { "\(dateLabel)-\(grade.rawValue)" }
        let dateLabel: String
        let grade: GradeDisplay
        let value: Double
    }

    /// Pengelompokan kolom sekarang mengambil indeks dan label dari
    /// `TrendDateContext` — persis daftar yang juga dipakai filter tanggal di
    /// Log Mangga Reject, jadi kedua layar tidak bisa lagi berbeda.
    private var stackedChartData: [StackedChartItem] {
        let context = dateContext
        var groupMap: [Int: [GradeDisplay: Double]] = [:]

        for record in dateFilteredRecords {
            let val = selectedMetric == .quantity ? 1.0 : (record.weightGrams / 1000.0)
            let index = context.bucketIndex(for: record.timestamp)
            groupMap[index, default: [:]][record.grade, default: 0.0] += val
        }

        var items: [StackedChartItem] = []
        for bucket in context.buckets {
            let gradeDict = groupMap[bucket.index] ?? [:]
            for grade in [GradeDisplay.reject, GradeDisplay.c, GradeDisplay.b, GradeDisplay.a] {
                let val = gradeDict[grade] ?? 0.0
                items.append(
                    StackedChartItem(dateLabel: bucket.label, grade: grade, value: val)
                )
            }
        }
        return items
    }
}

// MARK: - Tren Subcomponents

private struct TrendMetricSummaryCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: .rect(cornerRadius: 24))
    }
}

private struct TrendRejectedSummaryCard: View {
    let count: Int
    let onPeriksa: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
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
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: .rect(cornerRadius: 24))
    }
}

// MARK: - DateRangePickerPopover

class DateRangePickerViewModel: ObservableObject {
    @Published var pendingFilter: DateRangeFilter
    @Published var pendingAnchorDate: Date
    
    init(filter: DateRangeFilter, anchor: Date) {
        self.pendingFilter = filter
        self.pendingAnchorDate = anchor
    }
}

struct DateRangePickerPopover: View {
    @Binding var selectedFilter: DateRangeFilter
    @Binding var anchorDate: Date?
    @Binding var isPresented: Bool
    
    @StateObject private var model: DateRangePickerViewModel
    
    init(selectedFilter: Binding<DateRangeFilter>, anchorDate: Binding<Date?>, isPresented: Binding<Bool>, defaultAnchor: Date) {
        self._selectedFilter = selectedFilter
        self._anchorDate = anchorDate
        self._isPresented = isPresented
        
        let initialFilter = selectedFilter.wrappedValue
        let initialAnchor = anchorDate.wrappedValue ?? defaultAnchor
        self._model = StateObject(wrappedValue: DateRangePickerViewModel(filter: initialFilter, anchor: initialAnchor))
    }
    
    var computedStartDate: Date {
        let calendar = Calendar.current
        switch model.pendingFilter {
        case .last7:
            return calendar.date(byAdding: .day, value: -6, to: model.pendingAnchorDate) ?? model.pendingAnchorDate
        case .last30:
            return calendar.date(byAdding: .day, value: -29, to: model.pendingAnchorDate) ?? model.pendingAnchorDate
        case .last90:
            return calendar.date(byAdding: .day, value: -89, to: model.pendingAnchorDate) ?? model.pendingAnchorDate
        }
    }
    
    var computedEndDate: Date {
        return model.pendingAnchorDate
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // LEFT SIDEBAR
            VStack(alignment: .leading, spacing: 16) {
                Text("Rentang Waktu")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 4) {
                    ForEach([DateRangeFilter.last7, DateRangeFilter.last30, DateRangeFilter.last90], id: \.self) { filter in
                        Button(action: { model.pendingFilter = filter }) {
                            Text(filter.rawValue)
                                .font(.system(size: 16, weight: model.pendingFilter == filter ? .semibold : .regular))
                                .foregroundStyle(model.pendingFilter == filter ? Color.blue : Color.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(model.pendingFilter == filter ? Color(red: 224/255, green: 241/255, blue: 255/255) : Color.clear, in: .rect(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                Spacer()
            }
            .frame(width: 190)
            .background(Color(white: 0.98))
            
            Divider()
            
            // RIGHT SIDE (Calendar & Buttons)
            VStack(alignment: .leading, spacing: 0) {
                // Top Date Range labels
                HStack(spacing: 12) {
                    dateLabel(date: computedStartDate)
                    Text("-")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                    dateLabel(date: computedEndDate)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                Divider()
                
                // Graphical DatePicker
                CustomRangeCalendar(
                    anchorDate: $model.pendingAnchorDate,
                    rangeFilter: model.pendingFilter,
                    startDate: computedStartDate,
                    endDate: computedEndDate
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Divider()
                
                // Bottom Buttons
                HStack(spacing: 16) {
                    Spacer()
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.93), in: .capsule)
                    
                    Button("Apply") {
                        selectedFilter = model.pendingFilter
                        anchorDate = model.pendingAnchorDate
                        isPresented = false
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue, in: .capsule)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .frame(width: 390)
            .background(Color.white)
        }
        .frame(width: 581, height: 530)
        .background(Color.white)
    }
    
    private func dateLabel(date: Date) -> some View {
        let dayNumber = Calendar.current.component(.day, from: date)
        let iconName = "\(dayNumber).square"
        return HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(Color(red: 142/255, green: 142/255, blue: 147/255))
                .font(.system(size: 18))
            Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.system(size: 16))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(red: 228/255, green: 228/255, blue: 229/255), lineWidth: 1)
        )
    }
}

// MARK: - CustomRangeCalendar

struct CustomRangeCalendar: View {
    @Binding var anchorDate: Date
    let rangeFilter: DateRangeFilter
    let startDate: Date
    let endDate: Date
    
    @State private var monthBaseDate: Date = Date()
    
    let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text(monthBaseDate.formatted(.dateTime.month().year()))
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                HStack(spacing: 24) {
                    Button(action: { shiftMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { shiftMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 4)
            
            // Days of week
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Grid
            let gridDays = getGridDays()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(gridDays, id: \.date) { day in
                    if day.isCurrentMonth {
                        let isSelected = isInRange(day.date)
                        let isAnchor = Calendar.current.isDate(day.date, inSameDayAs: anchorDate)
                        
                        Button(action: {
                            anchorDate = day.date
                        }) {
                            Text("\(Calendar.current.component(.day, from: day.date))")
                                .font(.system(size: 15, weight: isAnchor ? .bold : .regular))
                                .foregroundStyle(isAnchor ? .white : (isSelected ? Color.blue : .primary))
                                .frame(width: 36, height: 36)
                                .background(
                                    isAnchor ? Color.blue : (isSelected ? Color(red: 224/255, green: 241/255, blue: 255/255) : Color.clear),
                                    in: .circle
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("")
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .onAppear {
            monthBaseDate = anchorDate
        }
    }
    
    private func shiftMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: monthBaseDate) {
            monthBaseDate = newDate
        }
    }
    
    private func isInRange(_ date: Date) -> Bool {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let end = cal.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return date >= start && date <= end
    }
    
    struct GridDay {
        let date: Date
        let isCurrentMonth: Bool
    }
    
    private func getGridDays() -> [GridDay] {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: monthBaseDate))!
        let firstWeekday = cal.component(.weekday, from: startOfMonth)
        let offset = firstWeekday - 1
        
        let startOfGrid = cal.date(byAdding: .day, value: -offset, to: startOfMonth)!
        
        var days: [GridDay] = []
        for i in 0..<42 {
            let date = cal.date(byAdding: .day, value: i, to: startOfGrid)!
            let isCurrentMonth = cal.component(.month, from: date) == cal.component(.month, from: monthBaseDate)
            days.append(GridDay(date: date, isCurrentMonth: isCurrentMonth))
        }
        return days
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
            .background(Color(red: 142/255, green: 142/255, blue: 147/255))

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

                    Text(String(format: "%.1f", weightForGrade(grade)))
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
    HistoryScreen(allRecords: DummyDataStore.generateDummyRecords())
}
