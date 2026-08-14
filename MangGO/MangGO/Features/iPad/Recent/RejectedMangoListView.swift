import SwiftUI

struct RejectedMangoListView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var records: [MangoRecord] = DummyDataStore.generateDummyRecords(days: 7)
        .filter { $0.grade == .reject }
    
    // State untuk Multi-select Date Filter Overlay
    @State private var isDateFilterPresented: Bool = false
    @State private var availableDates: [String] = ["8 Apr", "9 Apr", "10 Apr", "11 Apr", "12 Apr", "13 Apr", "14 Apr"]
    @State private var selectedDates: Set<String> = ["9 Apr", "10 Apr", "12 Apr", "14 Apr"]
    
    // State untuk Sorting
    @State private var selectedSort: RecentSortOption = .newestTimestamp
    @State private var selectedRecordForDetail: MangoRecord? = nil
    @State private var navigateToDetail: Bool = false
    
    var filteredAndSortedRecords: [MangoRecord] {
        let sorted = records
        switch selectedSort {
        case .newestTimestamp: return sorted.sorted { $0.timestamp > $1.timestamp }
        case .oldestTimestamp: return sorted.sorted { $0.timestamp < $1.timestamp }
        case .heaviest: return sorted.sorted { $0.weightGrams > $1.weightGrams }
        case .lightest: return sorted.sorted { $0.weightGrams < $1.weightGrams }
        case .lowestDefect: return sorted.sorted { $0.defectPercent < $1.defectPercent }
        case .highestDefect: return sorted.sorted { $0.defectPercent > $1.defectPercent }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 247/255, green: 247/255, blue: 248/255)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Header Bar
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
                            Text("Tren 7 Hari")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            Text("8 Apr, 2026 - 14 Apr, 2026")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    // MARK: - Filter & Sort Bar
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Log Mangga Reject")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                        
                        HStack(spacing: 12) {
                            // Filter Tanggal Button with Popover Dropdown
                            Button(action: { isDateFilterPresented.toggle() }) {
                                HStack(spacing: 8) {
                                    Text("Filter Tanggal")
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                            .popover(isPresented: $isDateFilterPresented) {
                                DateFilterOverlayView(
                                    availableDates: availableDates,
                                    selectedDates: $selectedDates
                                )
                                .frame(width: 240, height: 320)
                            }
                            
                            // Urutkan Button
                            Menu {
                                Picker("Urutkan", selection: $selectedSort) {
                                    ForEach(RecentSortOption.allCases) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Urutkan")
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "line.3.horizontal.decrease")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    
                    // MARK: - Table Card
                    VStack(spacing: 0) {
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
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                if let record = selectedRecordForDetail {
                    RejectedMangoDetailView(selectedRecord: record, allRecords: records, contextTitle: "Tren 7 Hari")
                }
            }
        }
        .navigationViewStyle(.stack)
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

// MARK: - Overlay Multiple Selection Date Filter Component
struct DateFilterOverlayView: View {
    let availableDates: [String]
    @Binding var selectedDates: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(availableDates, id: \.self) { dateStr in
                        let isSelected = selectedDates.contains(dateStr)
                        Button(action: {
                            if isSelected {
                                selectedDates.remove(dateStr)
                            } else {
                                selectedDates.insert(dateStr)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 18))
                                    .foregroundColor(isSelected ? .blue : .gray)
                                
                                Text(dateStr)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.blue.opacity(0.12) : Color.clear)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(10)
            }
        }
        .background(Color.white)
    }
}

#Preview(traits: .landscapeLeft) {
    RejectedMangoListView()
}
