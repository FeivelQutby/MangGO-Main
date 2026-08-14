import SwiftUI

enum RecentSortOption: String, CaseIterable, Identifiable {
    case newestTimestamp = "Timestamp Terbaru"
    case oldestTimestamp = "Timestamp Terlama"
    case heaviest = "Paling Berat"
    case lightest = "Paling Ringan"
    case lowestDefect = "Tingkat Defect Terendah"
    case highestDefect = "Tingkat Defect Tertinggi"
    
    var id: String { rawValue }
}

struct RecentScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    // Sample state data harian (1 hari)
    @State private var records: [MangoRecord] = DummyDataStore.generateDummyRecords(days: 1)
        .filter { $0.grade == .reject }
    
    @State private var selectedSort: RecentSortOption = .newestTimestamp
    @State private var selectedRecordForDetail: MangoRecord? = nil
    @State private var navigateToDetail: Bool = false
    
    // Sorted records berdasarkan pilihan sort
    var sortedRecords: [MangoRecord] {
        switch selectedSort {
        case .newestTimestamp:
            return records.sorted { $0.timestamp > $1.timestamp }
        case .oldestTimestamp:
            return records.sorted { $0.timestamp < $1.timestamp }
        case .heaviest:
            return records.sorted { $0.weightGrams > $1.weightGrams }
        case .lightest:
            return records.sorted { $0.weightGrams < $1.weightGrams }
        case .lowestDefect:
            return records.sorted { $0.defectPercent < $1.defectPercent }
        case .highestDefect:
            return records.sorted { $0.defectPercent > $1.defectPercent }
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
                            Text("Data Harian")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            Text("4 Apr, 2026")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    // MARK: - Title & Sort Button (Khusus Recent Screen: Cuma Sort)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Log Mangga Reject")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                        
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
                    
                    // MARK: - Reject Log Table
                    VStack(spacing: 0) {
                        // Header
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
                        
                        // Rows
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(sortedRecords.enumerated()), id: \.element.id) { index, record in
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
                    RejectedMangoDetailView(selectedRecord: record, allRecords: records, contextTitle: "Data Harian")
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
#Preview("Recent Screen", traits: .landscapeLeft) {
    RecentScreen()
}

