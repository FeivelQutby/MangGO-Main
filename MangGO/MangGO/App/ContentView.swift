//
//  ContentView.swift
//  MangGO-q
//
//  Created by Feivel Qutby on 06/08/26.
//

import SwiftUI

struct ContentView: View {

    var body: some View {

        if UIDevice.current.userInterfaceIdiom == .pad {
            DashboardView()
        } else {
            WaitingView()
        }

    }
}

#Preview {
    ContentView()
}
