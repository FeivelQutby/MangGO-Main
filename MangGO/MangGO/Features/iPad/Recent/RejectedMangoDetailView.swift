//
//  RejectedMangoDetailView.swift
//  MangGO
//
//  Created from Figma Node 387:1271
//

import SwiftUI

/// Layar Detail Mangga Ter-Reject sesuai Figma 387:1271
struct RejectedMangoDetailView: View {

    let allRejected: [MangoRecord]
    @State private var currentIndex: Int

    @Environment(\.dismiss) private var dismiss

    init(allRejected: [MangoRecord], initialRecord: MangoRecord) {
        self.allRejected = allRejected
        let foundIndex = allRejected.firstIndex(where: { $0.id == initialRecord.id }) ?? 0
        _currentIndex = State(initialValue: foundIndex)
    }

    private var currentRecord: MangoRecord? {
        guard allRejected.indices.contains(currentIndex) else { return nil }
        return allRejected[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let record = currentRecord {
                    // Header Bar with Previous / Next navigation chevrons
                    HStack {
                        Button {
                            if currentIndex > 0 { currentIndex -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .padding(12)
                                .background(Color(.secondarySystemBackground), in: .circle)
                        }
                        .disabled(currentIndex <= 0)

                        Spacer()

                        VStack(spacing: 4) {
                            Text(record.formattedCode)
                                .font(.title.bold())
                            Text("Mangga Reject (\(currentIndex + 1) dari \(allRejected.count))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            if currentIndex < allRejected.count - 1 { currentIndex += 1 }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2.bold())
                                .padding(12)
                                .background(Color(.secondarySystemBackground), in: .circle)
                        }
                        .disabled(currentIndex >= allRejected.count - 1)
                    }
                    .padding(.horizontal, 24)

                    // Dual Photo Display (SISI A and SISI B)
                    HStack(spacing: 20) {
                        SidePhotoCard(title: "SISI A", isPrimary: true)
                        SidePhotoCard(title: "SISI B", isPrimary: false)
                    }
                    .padding(.horizontal, 24)

                    // Metrics & Failure Reasons
                    HStack(spacing: 24) {
                        // Card 1: Berat
                        MetricDetailTile(
                            icon: "⚖️",
                            title: "berat",
                            value: "\(Int(record.weightGrams)) gram",
                            status: record.weightStatus,
                            isWarning: record.weightGrams < 351
                        )

                        // Card 2: Defek Bintik / Blush
                        MetricDetailTile(
                            icon: "🚩",
                            title: "bintik defek",
                            value: String(format: "%.0f%%", record.defectPercent),
                            status: record.defectStatus,
                            isWarning: record.defectPercent > 15
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                } else {
                    ContentUnavailableView(
                        "Data Tidak Ditemukan",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Detail mangga tidak dapat dimuat.")
                    )
                }
            }
            .padding(.top, 16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Subcomponents

private struct SidePhotoCard: View {
    let title: String
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 260)

                VStack(spacing: 12) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Tampilan Kamera (\(title))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MetricDetailTile: View {
    let icon: String
    let title: String
    let value: String
    let status: String
    let isWarning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text(icon).font(.title2)
                Text(value)
                    .font(.title2.bold())
            }

            HStack(spacing: 6) {
                Image(systemName: isWarning ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(isWarning ? .red : .green)
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(isWarning ? .red : .green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isWarning ? Color.red.opacity(0.12) : Color.green.opacity(0.12), in: .capsule)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    let dummies = DummyDataStore.generateDummyRecords().filter { $0.grade == .reject }
    RejectedMangoDetailView(
        allRejected: dummies,
        initialRecord: dummies.first ?? MangoRecord(grade: .reject, weightGrams: 138, volumeCm3: 180, blushPercent: 0, defectPercent: 78, rejectionReason: "Defect tinggi")
    )
}
