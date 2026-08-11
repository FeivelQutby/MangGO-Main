//
//  DisconnectedScreen.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Ditampilkan saat link ke iPhone kamera putus.
struct DisconnectedScreen: View {

    var message: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text("Menunggu iPhone Kamera").font(.system(size: 40, weight: .semibold))
            Text("Pastikan iPhone di dalam box menyala, Wi-Fi dan Bluetooth aktif.")
                .font(.title3)
                .foregroundStyle(.secondary)
            if let message {
                Label(message, systemImage: "wifi.exclamationmark")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
        }
        .multilineTextAlignment(.center)
        .padding(40)
    }
}

#Preview { DisconnectedScreen(message: "Koneksi terputus") }
