//
//  MetricTile.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Kotak angka tunggal dengan judul kecil di atasnya.
struct MetricTile: View {

    let title: String
    let value: Double?
    let unit: String
    let digits: Int

    init(_ title: String, value: Double?, unit: String, digits: Int) {
        self.title = title
        self.value = value
        self.unit = unit
        self.digits = digits
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))
    }

    /// Unit digabung di luar `String(format:)` — kalau "%" masuk ke format
    /// string dia dibaca sebagai specifier dan hasilnya sampah.
    private var text: String {
        guard let value else { return "—" }
        return String(format: "%.\(digits)f", value) + " " + unit
    }
}

#Preview {
    HStack(spacing: 16) {
        MetricTile("Berat", value: 372, unit: "g", digits: 0)
        MetricTile("Bintik", value: 11.4, unit: "%", digits: 1)
        MetricTile("Volume", value: nil, unit: "cm³", digits: 0)
    }
    .padding()
}
