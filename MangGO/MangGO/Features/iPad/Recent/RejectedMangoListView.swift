//
//  RejectedMangoListView.swift
//  MangGO
//
//  Created from Figma Node 551:9554 & 551:9635 (Detail - Log Reject Harian & Sort Popover)
//

import SwiftUI

/// Options untuk popover urutkan
enum RejectSortOption: String, CaseIterable, Identifiable {
    case timestampNewest = "Timestamp Terbaru"
    case timestampOldest = "Timestamp Terlama"
    case weightHeaviest = "Paling Berat"
    case weightLightest = "Paling Ringan"
    case defectHighest = "Tingkat Defect Tertinggi"
    case defectLowest = "Tingkat Defect Terendah"

    var id: String { rawValue }
}

/// Layar Full Screen "Log Mangga Reject" sesuai Figma Node 551:9554
struct RejectedMangoListView: View {

    let rejectedRecords: [MangoRecord]

    /// Label asal layar — "Data Harian" atau "Tren 7 Hari" dst. Ikut ditampilkan
    /// di header dan diteruskan ke layar detail.
    var contextTitle: String = "Data Harian"

    /// Diisi hanya kalau layar ini dibuka dari Tren. Rentang dan kelompok
    /// tanggalnya datang utuh dari layar Tren, jadi filter waktu di sini adalah
    /// penyempitan dari pilihan sebelumnya — bukan filter baru yang berdiri
    /// sendiri. `nil` (mis. dari Data Harian) berarti tombol filter tanggal
    /// tidak relevan dan tidak ditampilkan.
    var dateContext: TrendDateContext? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var sortOption: RejectSortOption = .timestampNewest
    @State private var showingSortPopover = false
    @State private var showingDateFilterPopover = false
    @State private var selectedRecordForDetail: MangoRecord? = nil

    /// `nil` = belum disentuh operator, artinya seluruh kelompok ikut tampil.
    /// Begitu ada satu centang dilepas, isinya jadi daftar kelompok yang aktif.
    @State private var selectedBucketIDs: Set<Int>? = nil

    private var buckets: [TrendDateContext.Bucket] {
        dateContext?.buckets ?? []
    }

    /// Kelompok yang tercentang saat ini — default semua.
    private var activeBucketIDs: Set<Int> {
        selectedBucketIDs ?? Set(buckets.map(\.id))
    }

    private var isDateFilterNarrowed: Bool {
        guard let selectedBucketIDs else { return false }
        return selectedBucketIDs.count != buckets.count
    }

    private func toggleBucket(_ id: Int) {
        var next = activeBucketIDs
        if next.contains(id) {
            next.remove(id)
        } else {
            next.insert(id)
        }
        selectedBucketIDs = next
    }

    private var filteredAndSortedRecords: [MangoRecord] {
        var list = rejectedRecords

        // Penyempitan per kelompok tanggal. Dilewati kalau operator belum
        // mengubah apa pun, supaya hasilnya identik dengan sebelum fitur ini ada.
        if let dateContext, let selectedBucketIDs {
            list = list.filter {
                selectedBucketIDs.contains(dateContext.bucketIndex(for: $0.timestamp))
            }
        }

        if !searchText.isEmpty {
            list = list.filter {
                $0.formattedCode.localizedCaseInsensitiveContains(searchText) ||
                $0.id.uuidString.localizedCaseInsensitiveContains(searchText) ||
                ($0.rejectionReason?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        switch sortOption {
        case .timestampNewest:
            list.sort(by: { $0.timestamp > $1.timestamp })
        case .timestampOldest:
            list.sort(by: { $0.timestamp < $1.timestamp })
        case .weightHeaviest:
            list.sort(by: { $0.weightGrams > $1.weightGrams })
        case .weightLightest:
            list.sort(by: { $0.weightGrams < $1.weightGrams })
        case .defectHighest:
            list.sort(by: { $0.defectPercent > $1.defectPercent })
        case .defectLowest:
            list.sort(by: { $0.defectPercent < $1.defectPercent })
        }
        return list
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ==========================================
            // TOP BAR NAVIGATION (Figma Spec)
            // ==========================================
            HStack(spacing: 16) {
                // Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(red: 26/255, green: 26/255, blue: 26/255))
                        .padding(12)
                        .background(Color.white, in: .circle)
                }

                // Title & Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(contextTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(red: 26/255, green: 26/255, blue: 26/255))

                    Text(headerSubtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 114/255, green: 114/255, blue: 114/255))
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color(red: 242/255, green: 242/255, blue: 247/255))

            Divider()

            // ==========================================
            // MAIN CONTENT BODY
            // ==========================================
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Title + Urutkan Button under Title
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Log Mangga Reject")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color(red: 26/255, green: 26/255, blue: 26/255))

                        HStack(spacing: 12) {
                            // Filter tanggal hanya muncul kalau layar ini dibuka
                            // dari Tren — kelompoknya persis kolom bar chart di
                            // sana, jadi pilihan filter sebelumnya tidak hilang.
                            if dateContext != nil {
                                Button(action: { showingDateFilterPopover = true }) {
                                    HStack(spacing: 8) {
                                        Text(dateFilterLabel)
                                            .font(.system(size: 16, weight: .medium))
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundStyle(isDateFilterNarrowed ? Color.blue : .black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white, in: .capsule)
                                }
                                .popover(isPresented: $showingDateFilterPopover) {
                                    dateFilterPopover
                                        .presentationCompactAdaptation(.popover)
                                }
                            }

                            Button(action: { showingSortPopover = true }) {
                                HStack(spacing: 8) {
                                    Text("Urutkan")
                                        .font(.system(size: 16, weight: .medium))
                                    Image(systemName: "line.3.horizontal.decrease")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white, in: .capsule)
                            }
                            .popover(isPresented: $showingSortPopover) {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(RejectSortOption.allCases) { option in
                                        Button(action: {
                                            sortOption = option
                                            showingSortPopover = false
                                        }) {
                                            HStack {
                                                Text(option.rawValue)
                                                    .font(.system(size: 16, weight: sortOption == option ? .semibold : .medium))
                                                    .foregroundStyle(sortOption == option ? Color(red: 0/255, green: 136/255, blue: 255/255) : Color.black)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                sortOption == option ? Color(red: 224/255, green: 241/255, blue: 255/255) : Color.clear,
                                                in: .rect(cornerRadius: 8)
                                            )
                                        }
                                    }
                                }
                                .padding(12)
                                .frame(width: 260)
                                .presentationCompactAdaptation(.popover)
                            }
                        }
                    }

                    // Table Container (Log Mangga Reject Table)
                    if filteredAndSortedRecords.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.green)
                            Text("Tidak Ada Data Mangga Reject")
                                .font(.system(size: 20, weight: .bold))
                            Text("Semua mangga pada batch ini memenuhi standar kualitas.")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(red: 114/255, green: 114/255, blue: 114/255))
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                        .background(Color.white, in: .rect(cornerRadius: 24))
                    } else {
                        VStack(spacing: 0) {
                            // Table Header Row (#595959 Dark Gray)
                            HStack {
                                Text("Kode Mangga")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Tanggal")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                Text("Timestamp")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                Text("Berat")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                Text("Tingkat Defect")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                // Empty header text for Detail column
                                Text("")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 100, alignment: .center)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color(red: 89/255, green: 89/255, blue: 89/255))

                            // Table Data Rows
                            ForEach(Array(filteredAndSortedRecords.enumerated()), id: \.element.id) { index, record in
                                RejectedMangoRowView(index: index, record: record) {
                                    selectedRecordForDetail = record
                                }
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
                .padding(40)
            }
            .background(Color(red: 242/255, green: 242/255, blue: 247/255))
        }
        .sheet(item: $selectedRecordForDetail) { record in
            RejectedMangoDetailView(
                selectedRecord: record,
                allRecords: filteredAndSortedRecords,
                contextTitle: contextTitle
            )
            // Sheet form-sheet bawaan iPad terlalu sempit untuk dua foto
            // berdampingan + tiga kartu penyebab; `.page` melebarkannya tanpa
            // mengubah gaya presentasi.
            .presentationSizing(.page)
        }
    }

    // MARK: - Header helpers

    private var headerSubtitle: String {
        if let dateContext {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            formatter.locale = Locale(identifier: "id_ID")
            return "\(formatter.string(from: dateContext.startDate)) - \(formatter.string(from: dateContext.endDate))"
        }

        let date = rejectedRecords.first?.timestamp ?? Date()
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private var dateFilterLabel: String {
        guard isDateFilterNarrowed else { return "Filter Tanggal" }
        return "Filter Tanggal (\(activeBucketIDs.count)/\(buckets.count))"
    }

    // MARK: - Date Filter Popover

    /// Daftar centang per kelompok tanggal, mengikuti rentang yang dipilih di
    /// layar Tren. Barisnya sama dengan kolom bar chart di sana.
    private var dateFilterPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(contextTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 114/255, green: 114/255, blue: 114/255))

                Spacer()

                Button(isDateFilterNarrowed ? "Pilih Semua" : "Hapus Semua") {
                    selectedBucketIDs = isDateFilterNarrowed ? nil : []
                }
                .font(.system(size: 14, weight: .medium))
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 0/255, green: 136/255, blue: 255/255))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(buckets) { bucket in
                    let isOn = activeBucketIDs.contains(bucket.id)

                    Button {
                        toggleBucket(bucket.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isOn ? "checkmark.square.fill" : "square")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(
                                    isOn
                                    ? Color(red: 0/255, green: 136/255, blue: 255/255)
                                    : Color(red: 174/255, green: 174/255, blue: 178/255)
                                )

                            Text(bucket.label)
                                .font(.system(size: 16, weight: isOn ? .semibold : .regular))
                                .foregroundStyle(
                                    isOn
                                    ? Color(red: 0/255, green: 136/255, blue: 255/255)
                                    : Color.black
                                )

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            isOn
                            ? Color(red: 224/255, green: 241/255, blue: 255/255)
                            : Color.clear,
                            in: .rect(cornerRadius: 8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(width: 280)
    }
}

// MARK: - Subcomponents

private struct RejectedMangoRowView: View {
    let index: Int
    let record: MangoRecord
    let onDetail: () -> Void

    var body: some View {
        HStack {
            Text(record.formattedCode)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(red: 26/255, green: 26/255, blue: 26/255))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(record.timestamp.formatted(date: .numeric, time: .omitted))
                .font(.system(size: 18))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(record.timestamp.formatted(date: .omitted, time: .standard))
                .font(.system(size: 18))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("\(Int(record.weightGrams)) g")
                .font(.system(size: 18))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(String(format: "%.0f%%", record.defectPercent))
                .font(.system(size: 18))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)

            Button(action: onDetail) {
                Text("Detail")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue, in: .capsule)
                    .foregroundStyle(.white)
            }
            .frame(width: 100, alignment: .center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(index % 2 == 1 ? Color(red: 116/255, green: 116/255, blue: 128/255).opacity(0.08) : Color.white)
    }
}

#Preview {
    RejectedMangoListView(
        rejectedRecords: DummyDataStore.generateDummyRecords().filter { $0.grade == .reject }
    )
}
