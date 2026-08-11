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
            iPadView()
        } else {
            iPhoneView()
        }

    }
}

#Preview {
    ContentView()
}
