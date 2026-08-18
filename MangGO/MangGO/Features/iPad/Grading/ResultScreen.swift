//
//  ResultScreen.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Layar hasil satu buah: warna penuh layar supaya terbaca dari jarak jauh
/// di lantai pabrik.
struct ResultScreen: View {

    let grade: GradeDisplay
    let reason: String?

    var body: some View {
        ZStack {
            grade.color.ignoresSafeArea()
            VStack(spacing: 24) {
                Text(grade.headline)
                    .font(.system(size: 130, weight: .black))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                if let reason {
                    Text(reason).font(.system(size: 30, weight: .medium))
                }
            }
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .padding(48)
        }
    }
}

#Preview("Grade A") { ResultScreen(grade: .a, reason: nil) }
#Preview("Grade B") { ResultScreen(grade: .b, reason: nil) }
#Preview("Grade C") { ResultScreen(grade: .c, reason: nil) }
#Preview("Reject") { ResultScreen(grade: .reject, reason: "Bintik: 24.0% permukaan") }
