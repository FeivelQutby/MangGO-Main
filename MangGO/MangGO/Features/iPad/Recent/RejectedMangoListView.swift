//
//  RejectedMangoListView.swift
//  MangGO
//
//  Created from Figma Node 387:1233
//

import SwiftUI

/// Layar Daftar Mangga Ter-Reject sesuai Figma 387:1233
struct RejectedMangoListView: View {

    let rejectedRecords: [MangoRecord]

    @State private var searchText = ""
    @State private var selectedRecordForDetail: MangoRecord? = nil

    private var filteredRecords: [MangoRecord] {
        if searchText.isEmpty {
            return rejectedRecords
        }
        return rejectedRecords.filter {
            $0.formattedCode.localizedCaseInsensitiveContains(searchText) ||
            $0.id.uuidString.localizedCaseInsensitiveContains(searchText) ||
            ($0.rejectionReason?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // List of Rejected Items
                if filteredRecords.isEmpty {
                    ContentUnavailableView(
                        "Tidak Ada Data Mangga Reject",
                        systemImage: "checkmark.circle",
                        description: Text("Semua mangga pada batch ini memenuhi standar kualitas.")
                    )
                } else {
                    List(filteredRecords) { record in
                        HStack(spacing: 20) {
                            // Code badge
                            Text(record.formattedCode)
                                .font(.headline.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(GradeDisplay.reject.color.opacity(0.15))
                                .foregroundStyle(GradeDisplay.reject.color)
                                .clipShape(Capsule())

                            // Time & Details
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.subheadline.bold())
                                Text(record.rejectionReason ?? "Defek bintik melebihi ambang batas")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // Metrics: Weight & Defect
                            HStack(spacing: 24) {
                                HStack(spacing: 4) {
                                    Text("⚖️").font(.caption)
                                    Text("\(Int(record.weightGrams)) g")
                                        .font(.subheadline.bold())
                                }

                                HStack(spacing: 4) {
                                    Text("🚩").font(.caption)
                                    Text(String(format: "%.0f%%", record.defectPercent))
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.red)
                                }

                                Button {
                                    selectedRecordForDetail = record
                                } label: {
                                    Text("Detail")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.accentColor, in: .capsule)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Daftar Mangga Reject")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Cari ID mangga (misal R48-007)...")
            .sheet(item: $selectedRecordForDetail) { record in
                RejectedMangoDetailView(
                    allRejected: rejectedRecords,
                    initialRecord: record
                )
            }
        }
    }
}

#Preview {
    RejectedMangoListView(
        rejectedRecords: DummyDataStore.generateDummyRecords(days: 1).filter { $0.grade == .reject }
    )
}
