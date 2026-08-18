import SwiftUI

struct RejectedMangoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Data record yang dipilih & list seluruh record
    @State var selectedRecord: MangoRecord
    let allRecords: [MangoRecord]
    
    // Subtitle dinamis ("Tren 7 Hari", "Tren 30 Hari", atau "Tren 3 Bulan")
    let contextTitle: String
    
    // State untuk Subtitle Header Dinamis, Sorting & Filter Tanggal
    @State private var dynamicDateRangeText: String = ""
    @State private var selectedSort: RecentSortOption = .newestTimestamp
    @State private var dateFilterItems: [DateFilterItem] = []
    @State private var showDateFilterPopover: Bool = false
    
    // Logika pengurutan & penyaringan daftar kode di sidebar kiri
    var filteredAndSortedRecords: [MangoRecord] {
        let activeFilters = dateFilterItems.filter { $0.isSelected }
        
        let dateFiltered = allRecords.filter { record in
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
        ZStack {
            Color(red: 247/255, green: 247/255, blue: 248/255)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Log Mangga Reject")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text(dynamicDateRangeText.isEmpty ? contextTitle : "\(contextTitle) (\(dynamicDateRangeText))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // MARK: - Action Filter Buttons (Desain Sesuai Screenshot)
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

                
                // MARK: - Main Content Split Area
                HStack(alignment: .top, spacing: 20) {
                    // Left Sidebar Code List
                    VStack(spacing: 0) {
                        Text("Kode")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 85/255, green: 85/255, blue: 85/255))
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(filteredAndSortedRecords) { record in
                                    Button(action: { selectedRecord = record }) {
                                        Text(record.formattedCode)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                selectedRecord.id == record.id
                                                ? Color.blue.opacity(0.12)
                                                : Color.white
                                            )
                                    }
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(width: 180)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    
                    // Right Detail Card
                    VStack(spacing: 24) {
                        Text("Detail Reject")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        
                        // Foto Mangga Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Foto Mangga")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            HStack(spacing: 20) {
                                MangoPhotoBox(title: "SISI A", imageName: "mango_side_a")
                                MangoPhotoBox(title: "SISI B", imageName: "mango_side_b")
                            }
                        }
                        
                        // Penyebab Reject Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Penyebab Reject")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            HStack(spacing: 16) {
                                RejectCauseCard(
                                    title: "berat",
                                    icon: "scalemass",
                                    value: "\(Int(selectedRecord.weightGrams)) gram",
                                    statusIcon: "xmark.circle.fill",
                                    statusText: selectedRecord.weightStatus,
                                    badgeColor: Color(red: 253/255, green: 238/255, blue: 240/255),
                                    textColor: Color(red: 180/255, green: 40/255, blue: 50/255)
                                )
                                
                                RejectCauseCard(
                                    title: "blush",
                                    icon: "flag.fill",
                                    value: "\(Int(selectedRecord.defectPercent))%",
                                    statusIcon: "arrow.up.right",
                                    statusText: "bintik/defek terlalu tinggi",
                                    badgeColor: Color(red: 253/255, green: 238/255, blue: 240/255),
                                    textColor: Color(red: 180/255, green: 40/255, blue: 50/255)
                                )
                                
                                RejectCauseCard(
                                    title: "warna",
                                    icon: "circle.fill",
                                    iconColor: .yellow,
                                    value: "kuning",
                                    statusIcon: "exclamationmark.triangle.fill",
                                    statusText: "mangga terlalu matang",
                                    badgeColor: Color(red: 253/255, green: 238/255, blue: 240/255),
                                    textColor: Color(red: 180/255, green: 40/255, blue: 50/255)
                                )
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            setupDateFiltersAndRange()
        }
    }

    
    // MARK: - Setup Logic Sinkronisasi Tanggal
    private func setupDateFiltersAndRange() {
        guard !allRecords.isEmpty else { return }
        
        // 1. Dapatkan Min & Max Date Nyata dari List Data Record
        guard let minDate = allRecords.map({ $0.timestamp }).min(),
              let maxDate = allRecords.map({ $0.timestamp }).max() else { return }
        
        let headerFormatter = DateFormatter()
        headerFormatter.dateFormat = "d MMM, yyyy"
        self.dynamicDateRangeText = "\(headerFormatter.string(from: minDate)) - \(headerFormatter.string(from: maxDate))"
        
        // 2. Generate Opsi Dropdown Berdasarkan Periode dan Tanggal Nyata Data
        let calendar = Calendar.current
        var items: [DateFilterItem] = []
        let labelFormatter = DateFormatter()
        
        if contextTitle.contains("7 Hari") {
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
        } else if contextTitle.contains("30 Hari") {
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
        } else {
            // Tren 3 Bulan
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
}

// MARK: - Subviews & Components

struct MangoPhotoBox: View {
    let title: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
            
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(16)
                .clipped()
        }
    }
}

struct RejectCauseCard: View {
    let title: String
    let icon: String
    var iconColor: Color = .gray
    let value: String
    let statusIcon: String
    let statusText: String
    let badgeColor: Color
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
            
            HStack(spacing: 4) {
                Image(systemName: statusIcon)
                    .font(.system(size: 10, weight: .bold))
                Text(statusText)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Previews (7 Hari, 30 Hari, & 3 Bulan)

#Preview("Tren 7 Hari", traits: .landscapeLeft) {
    let records = DummyDataStore.generateDummyRecords(days: 7)
    let rejectedRecords = records.filter { $0.grade == .reject }
    
    if let selectedRecord = rejectedRecords.first {
        RejectedMangoDetailView(
            selectedRecord: selectedRecord,
            allRecords: rejectedRecords,
            contextTitle: TrendPeriod.days7.rawValue
        )
    }
}

#Preview("Tren 30 Hari", traits: .landscapeLeft) {
    let records = DummyDataStore.generateDummyRecords(days: 30)
    let rejectedRecords = records.filter { $0.grade == .reject }
    
    if let selectedRecord = rejectedRecords.first {
        RejectedMangoDetailView(
            selectedRecord: selectedRecord,
            allRecords: rejectedRecords,
            contextTitle: TrendPeriod.days30.rawValue
        )
    }
}

#Preview("Tren 3 Bulan", traits: .landscapeLeft) {
    let records = DummyDataStore.generateDummyRecords(days: 90)
    let rejectedRecords = records.filter { $0.grade == .reject }
    
    if let selectedRecord = rejectedRecords.first {
        RejectedMangoDetailView(
            selectedRecord: selectedRecord,
            allRecords: rejectedRecords,
            contextTitle: TrendPeriod.months3.rawValue
        )
    }
}
