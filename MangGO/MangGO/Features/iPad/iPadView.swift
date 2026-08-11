//
//  iPadView.swift
//  MangGO
//
//  Created by Feivel Qutby on 07/08/26.
//

import SwiftUI

struct iPadView: View {
    @State private var state = 0
    
    var body: some View {
        VStack {
            Picker("", selection: $state) {
                Text("Grading").tag(0)
                Text("Dashboard").tag(1)
            }
            .pickerStyle(.segmented)

            switch state {
            case 0:
                GradingView()
            case 1:
                DashboardView()
            default:
                GradingView()
            }
        }
        .padding()
    }
}

#Preview {
    iPadView()
}
