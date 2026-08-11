//
//  SensorStatus.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Satu sumber kebenaran untuk warna & label status sensor. IdleScreen dan
/// Dashboard menampilkannya dengan bentuk berbeda, tapi arti warnanya harus
/// sama di seluruh aplikasi.
extension StationSnapshot.Sensors.State {

    var color: Color {
        switch self {
        case .ready: .green
        case .waiting: .orange
        case .offline: .red
        }
    }

    var label: String {
        switch self {
        case .ready: "Ready"
        case .waiting: "Waiting..."
        case .offline: "Not Ready"
        }
    }
}
