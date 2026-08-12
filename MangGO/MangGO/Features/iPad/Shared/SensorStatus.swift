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
        case .ready: Color(red: 0/255, green: 92/255, blue: 23/255)
        case .waiting: Color(red: 88/255, green: 66/255, blue: 0/255)
        case .offline: Color(red: 180/255, green: 0/255, blue: 0/255)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .ready: Color(red: 221/255, green: 255/255, blue: 229/255)
        case .waiting: Color(red: 255/255, green: 248/255, blue: 179/255)
        case .offline: Color(red: 255/255, green: 225/255, blue: 225/255)
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
