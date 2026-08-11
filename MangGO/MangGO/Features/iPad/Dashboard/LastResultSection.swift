//
//  LastResultSection.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Detail buah terakhir yang selesai dinilai: angka mentahnya plus alasan
/// kenapa grade-nya turun (kalau ada).
struct LastResultSection: View {

    let result: StationSnapshot.Result?

    var body: some View {
        if let result {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    MetricTile("Berat", value: result.weightGrams, unit: "g", digits: 0)
                    MetricTile("Volume", value: result.volumeCm3, unit: "cm³", digits: 0)
                    MetricTile("Blush", value: result.blushPercent, unit: "%", digits: 1)
                    MetricTile("Bintik", value: result.defectPercent, unit: "%", digits: 1)
                }

                HStack(spacing: 12) {
                    if let grade = GradeDisplay(rawValue: result.grade) {
                        Text(grade.headline)
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(grade.color, in: .capsule)
                    }
                    Text(result.reason ?? "Semua indikator dalam ambang batas")
                        .font(.title3)
                        .foregroundStyle(result.reason == nil ? Color.secondary : Color.orange)
                }
            }
        } else {
            Text("Belum ada buah yang selesai dinilai.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Ada hasil") {
    LastResultSection(result: .init(grade: "B", reason: "Bintik: 11.4% permukaan",
                                    weightGrams: 372, volumeCm3: 318,
                                    blushPercent: 9, defectPercent: 11.4,
                                    gradedAt: .now))
    .padding()
}

#Preview("Kosong") { LastResultSection(result: nil).padding() }
