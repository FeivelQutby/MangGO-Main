//
//  WaitingView.swift
//  MangGO-q
//
//  Created by Feivel Qutby on 07/08/26.
//

import SwiftUI

struct WaitingView: View {
    var body: some View {
        VStack(spacing: 20) {

            Text("Iphone App")
                .font(.largeTitle)
                .bold()

            Text("ESP32 Connected")
                .foregroundStyle(.green)

            Text("iPhone Connected")
                .foregroundStyle(.green)

            Toggle("Show Camera", isOn: .constant(false))
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    WaitingView()
}
