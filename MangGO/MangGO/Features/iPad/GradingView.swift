//
//  GradingView.swift
//  MangGO-q
//
//  Created by Feivel Qutby on 07/08/26.
//

import SwiftUI

struct GradingView: View {
    var body: some View {
        VStack {

            Text("Grading View")
                .font(.largeTitle)
                .bold()

            Text("Waiting for grading result...")
        }
        .padding()
    }
}

#Preview {
    GradingView()
}
