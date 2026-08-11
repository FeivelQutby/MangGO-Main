//
//  ContentView.swift
//  MangGO
//

import SwiftUI

/// Satu binary, dua peran. iPhone jadi station (kamera + inferensi + ESP32),
/// iPad jadi display. Peran dipilih dari idiom device, bukan dari toggle di UI,
/// supaya tidak ada cara untuk salah setel di lantai pabrik.
struct ContentView: View {

    private let isDisplay: Bool

    @State private var sync: StationSync

    init() {
        let display = UIDevice.current.userInterfaceIdiom == .pad
        self.isDisplay = display
        _sync = State(initialValue: StationSync(role: display ? .display : .station))
    }

    var body: some View {
        Group {
            if isDisplay {
                iPadView()
            } else {
                iPhoneView()
            }
        }
        .environment(sync)
        // `start()` idempoten, jadi aman kalau onAppear terpanggil lebih dari sekali.
        .onAppear { sync.start() }
    }
}

#Preview {
    ContentView()
}
