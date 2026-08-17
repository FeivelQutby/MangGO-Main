//
//  DashboardScreen.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Tab Dashboard: rekap jumlah per grade, detail buah terakhir, dan status
/// sensor. Isinya sengaja dipecah jadi beberapa section supaya tiap bagian
/// bisa dipreview dan diubah sendiri-sendiri.
struct DashboardScreen: View {

    // desain nya bisa di sini beb
    // .
    
    let snapshot: StationSnapshot

    private var totalProcessed: Int { snapshot.counts.values.reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Total diproses: \(totalProcessed)")
                .font(.title2.weight(.semibold))

            GradeCountRow(counts: snapshot.counts)

            Text("Buah Terakhir").font(.title3.weight(.bold))
            LastResultSection(result: snapshot.lastResult)

            Text("Status Sensor").font(.title3.weight(.bold))
            SensorSummaryRow(sensors: snapshot.sensors)

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    DashboardScreen(snapshot: StationSnapshot(
        phase: .done,
        lastResult: .init(id: UUID(), grade: "B", reason: "Bintik: 11.4% permukaan",
                          weightGrams: 372, defectPercent: 11.4, gradedAt: .now),
        counts: ["A": 12, "B": 5, "C": 2, "Reject": 1],
        sensors: .allReady,
        updatedAt: .now
    ))
}
