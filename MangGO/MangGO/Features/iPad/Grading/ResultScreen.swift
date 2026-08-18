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

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            grade.color
                .ignoresSafeArea()

            // MARK: - Close Button
            VStack {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                }

                Spacer()
            }

            // MARK: - Result
            VStack(spacing: 24) {
                Text(grade.headline)
                    .font(.system(size: 130, weight: .black))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)

                if let reason {
                    Text(reason)
                        .font(.system(size: 30, weight: .medium))
                }
            }
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .padding(48)
        }
        .task {
            try? await Task.sleep(for: .seconds(4))
            dismiss()
        }
    }
}

#Preview("Grade A") { ResultScreen(grade: .a, reason: nil) }
#Preview("Grade B") { ResultScreen(grade: .b, reason: nil) }
#Preview("Grade C") { ResultScreen(grade: .c, reason: nil) }
#Preview("Reject") { ResultScreen(grade: .reject, reason: "Bintik: 24.0% permukaan") }
