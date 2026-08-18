import SwiftUI

// MARK: - Enum Period Option
enum TrendPeriod: String, CaseIterable, Identifiable {
    case days7 = "Tren 7 Hari"
    case days30 = "Tren 30 Hari"
    case months3 = "Tren 3 Bulan"
    
    var id: String { rawValue }
    
    var dayCount: Int {
        switch self {
        case .days7: return 7
        case .days30: return 30
        case .months3: return 90
        }
    }
}

// MARK: - Model Filter Tanggal
struct DateFilterItem: Identifiable {
    let id = UUID()
    let label: String
    var isSelected: Bool
    let startDate: Date
    let endDate: Date
}

struct RejectedMangoListView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Parameter periode dari halaman tren
    let period: TrendPeriod
    
    // State data records & dynamic header date range
    @State private var records: [MangoRecord] = []
    @State private var dynamicDateRangeText: String = ""
    
    // State untuk Sorting & Filter Tanggal
    @State private var selectedSort: RecentSortOption = .newestTimestamp
    @State private var dateFilterItems: [DateFilterItem] = []
    @State private var showDateFilterPopover: Bool = false
    
    // State Navigation Detail
    @State private var selectedRecordForDetail: MangoRecord? = nil
    @State private var navigateToDetail: Bool = false
    
    init(period: TrendPeriod = .days7) {
        self.period = period
    }
    
    // MARK: - Filtering & Sorting Logic
    var filteredAndSortedRecords: [MangoRecord] {
        let activeFilters = dateFilterItems.filter { $0.isSelected }
        
        let dateFiltered = records.filter { record in
            if activeFilters.isEmpty { return true }
            return activeFilters.contains { filter in
                record.timestamp >= filter.startDate && record.timestamp <= filter.endDate
            }
        }
        
        switch selectedSort {
        case .newestTimestamp: return dateFiltered.sorted { $0.timestamp > $1.timestamp }
        case .oldestTimestamp: return dateFiltered.sorted { $0.timestamp < $1.timestamp }
        case .heaviest: return dateFiltered.sorted { $0.weightGrams > $1.weightGrams }
        case .lightest: return dateFiltered.sorted { $0.weightGrams < $1.weightGrams }
        case .lowestDefect: return dateFiltered.sorted { $0.defectPercent < $1.defectPercent }
        case .highestDefect: return dateFiltered.sorted { $0.defectPercent > $1.defectPercent }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color(red: 247/255, green: 247/255, blue: 248/255)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Header Bar Dinamis
                    HStack(spacing: 16) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(period.rawValue)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            Text(dynamicDateRangeText.isEmpty ? "Memuat tanggal..." : dynamicDateRangeText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // MARK: - Title & Filter Bar
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Log Mangga Reject")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 60)
                        
                        HStack(spacing: 12) {
                            // MARK: Button Filter Tanggal
                            Button(action: { showDateFilterPopover.toggle() }) {
                                SegmentedActionButton(
                                    title: "Filter Tanggal",
                                    iconName: "calendar"
                                )
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $showDateFilterPopover) {
                                DateFilterPopoverView(items: $dateFilterItems)
                                    .presentationCompactAdaptation(.popover)
                            }
                            
                            // MARK: Button Urutkan Menu
                            Menu {
                                Picker("Urutkan", selection: $selectedSort) {
                                    ForEach(RecentSortOption.allCases) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                            } label: {
                                SegmentedActionButton(
                                    title: "Urutkan",
                                    iconName: "line.3.horizontal.decrease"
                                )
                            }
                        }
                        .padding(.horizontal, 60)
                    }
                    
                    // MARK: - Table Card
                    VStack(spacing: 0) {
                        // Table Header
                        HStack {
                            Text("Kode Mangga").frame(maxWidth: .infinity, alignment: .center)
                            Text("Tanggal").frame(maxWidth: .infinity, alignment: .center)
                            Text("Timestamp").frame(maxWidth: .infinity, alignment: .center)
                            Text("Berat").frame(maxWidth: .infinity, alignment: .center)
                            Text("Tingkat Defect").frame(maxWidth: .infinity, alignment: .center)
                            Spacer().frame(width: 80)
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Color(red: 85/255, green: 85/255, blue: 85/255))
                        
                        // Table Rows
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(filteredAndSortedRecords.enumerated()), id: \.element.id) { index, record in
                                    HStack {
                                        Text(record.formattedCode)
                                            .font(.system(size: 14, weight: .bold))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        
                                        Text(formatDate(record.timestamp))
                                            .font(.system(size: 14, weight: .regular))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        
                                        Text(formatTime(record.timestamp))
                                            .font(.system(size: 14, weight: .regular))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        
                                        Text("\(Int(record.weightGrams))")
                                            .font(.system(size: 14, weight: .regular))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        
                                        Text("\(Int(record.defectPercent))%")
                                            .font(.system(size: 14, weight: .regular))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        
                                        Button(action: {
                                            selectedRecordForDetail = record
                                            navigateToDetail = true
                                        }) {
                                            Text("Detail")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 6)
                                                .background(Color.blue)
                                                .clipShape(Capsule())
                                        }
                                        .frame(width: 80, alignment: .center)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(index % 2 == 0 ? Color.white : Color(red: 245/255, green: 245/255, blue: 247/255))
                                }
                            }
                        }
                    }
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 60)
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 24)
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                if let record = selectedRecordForDetail {
                    RejectedMangoDetailView(
                        selectedRecord: record,
                        allRecords: filteredAndSortedRecords,
                        contextTitle: period.rawValue
                    )
                }
            }
            .onAppear {
                setupDataAndFilters()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Setup Data & Sinkronisasi Tanggal 100% Dynamic
    private func setupDataAndFilters() {
        let generatedRecords = DummyDataStore.generateDummyRecords(days: period.dayCount)
        let rejected = generatedRecords.filter { $0.grade == .reject }
        self.records = rejected
        
        guard let minDate = rejected.map({ $0.timestamp }).min(),
              let maxDate = rejected.map({ $0.timestamp }).max() else { return }
        
        // 1. Format Teks Subtitle Header
        let headerFormatter = DateFormatter()
        headerFormatter.dateFormat = "d MMM, yyyy"
        self.dynamicDateRangeText = "\(headerFormatter.string(from: minDate)) - \(headerFormatter.string(from: maxDate))"
        
        // 2. Format Generator Dropdown Tanggal
        setupDateFilters(minDate: minDate, maxDate: maxDate)
    }
    
    private func setupDateFilters(minDate: Date, maxDate: Date) {
        let calendar = Calendar.current
        var items: [DateFilterItem] = []
        let labelFormatter = DateFormatter()
        
        switch period {
        case .days7:
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: minDate) {
                    let startOfDay = calendar.startOfDay(for: date)
                    let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
                    
                    labelFormatter.dateFormat = "d MMM"
                    let label = labelFormatter.string(from: date)
                    
                    items.append(DateFilterItem(
                        label: label,
                        isSelected: true,
                        startDate: startOfDay,
                        endDate: endOfDay
                    ))
                }
            }
            
        case .days30:
            let segmentDays = 6
            labelFormatter.dateFormat = "d MMM"
            
            for index in 0..<5 {
                let startOffset = index * segmentDays
                let endOffset = min(startOffset + (segmentDays - 1), 29)
                
                if let startDate = calendar.date(byAdding: .day, value: startOffset, to: minDate),
                   let endDate = calendar.date(byAdding: .day, value: endOffset, to: minDate) {
                    let start = calendar.startOfDay(for: startDate)
                    let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
                    
                    let label = "\(labelFormatter.string(from: startDate)) - \(labelFormatter.string(from: endDate))"
                    
                    items.append(DateFilterItem(
                        label: label,
                        isSelected: true,
                        startDate: start,
                        endDate: end
                    ))
                }
            }
            
        case .months3:
            let segmentDays = 30
            labelFormatter.dateFormat = "d MMM"
            
            for index in 0..<3 {
                let startOffset = index * segmentDays
                let endOffset = min(startOffset + (segmentDays - 1), 89)
                
                if let startDate = calendar.date(byAdding: .day, value: startOffset, to: minDate),
                   let endDate = calendar.date(byAdding: .day, value: endOffset, to: minDate) {
                    let start = calendar.startOfDay(for: startDate)
                    let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
                    
                    let label = "\(labelFormatter.string(from: startDate)) - \(labelFormatter.string(from: endDate))"
                    
                    items.append(DateFilterItem(
                        label: label,
                        isSelected: true,
                        startDate: start,
                        endDate: end
                    ))
                }
            }
        }
        
        self.dateFilterItems = items
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Component Tombol Dua Warna (Sesuai Screenshot)
struct SegmentedActionButton: View {
    let title: String
    let iconName: String
    
    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black)
                .padding(.leading, 16)
                .padding(.trailing, 14)
                .padding(.vertical, 10)
                .background(Color.white)
            
            ZStack {
                Color(red: 238/255, green: 238/255, blue: 239/255)
                
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
            }
            .frame(width: 44, height: 40)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Subview Popover Filter Tanggal
struct DateFilterPopoverView: View {
    @Binding var items: [DateFilterItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach($items) { $item in
                Button(action: { item.isSelected.toggle() }) {
                    HStack(spacing: 12) {
                        Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(item.isSelected ? .blue : .gray.opacity(0.5))
                        
                        Text(item.label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(item.isSelected ? .blue : .black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(item.isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(Color.white)
    }
}

// MARK: - Previews
#Preview("Tren 7 Hari", traits: .landscapeLeft) {
    RejectedMangoListView(period: .days7)
}

#Preview("Tren 30 Hari", traits: .landscapeLeft) {
    RejectedMangoListView(period: .days30)
}

#Preview("Tren 3 Bulan", traits: .landscapeLeft) {
    RejectedMangoListView(period: .months3)
}
