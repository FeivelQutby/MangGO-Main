//
//  ResultScreen.swift
//  MangGO
//
//  Created by Rizki Hidayatul Laeli on 11/08/26.
//

import SwiftUI

/// Layar hasil satu buah: warna penuh layar supaya terbaca dari jarak jauh
/// di lantai pabrik.
///
/// Layar ini dipasang `iPadView` sebagai **overlay di dalam `ZStack`**, bukan
/// sheet dan bukan tujuan navigasi. Karena itu `@Environment(\.dismiss)` tidak
/// punya apa pun untuk ditutup — sebelumnya tombol X dan timer sama-sama
/// memanggilnya dan sama-sama tidak menghasilkan apa-apa. Penutupan sekarang
/// dilaporkan ke atas lewat `onClose`, dan pemiliknyalah yang menghapus overlay.
struct ResultScreen: View {

    let grade: GradeDisplay
    let reason: String?

    /// Lama layar bertahan sebelum menghilang sendiri. Operator tidak perlu
    /// menekan X kalau sudah lewat tenggat ini.
    var autoDismissAfter: Duration = .seconds(5)

    /// Dipanggil tepat satu kali, entah oleh tombol X atau oleh timer.
    var onClose: () -> Void = {}

    /// Penjaga supaya `close()` tidak pernah dieksekusi dua kali — misalnya
    /// timer yang kebetulan jatuh tempo di frame yang sama dengan tap operator.
    @State private var didClose = false

    var body: some View {
        ZStack {
            grade.color
                .ignoresSafeArea()

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
            // Teks memenuhi hampir seluruh layar; tanpa ini ia ikut menangkap
            // tap yang ditujukan ke tombol X di pojok.
            .allowsHitTesting(false)

            // MARK: - Close Button
            // Ditaruh paling akhir supaya berada di lapisan teratas ZStack.
            VStack {
                HStack {
                    Spacer()

                    Button {
                        close()
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
        }
        .task {
            // Suara hasil grading ikut muncul bersama layarnya.
            GradeAudioPlayer.shared.play(grade)

            // `.task` otomatis dibatalkan begitu view hilang. Jadi kalau
            // operator menekan X lebih dulu, `sleep` melempar CancellationError
            // dan `close()` di bawah tidak pernah tercapai — timer tidak bisa
            // menutup sesuatu yang sudah ditutup manual, dan tidak bisa
            // "menutup" buah berikutnya.
            try? await Task.sleep(for: autoDismissAfter)
            guard !Task.isCancelled else { return }

            close()
        }
        .onDisappear {
            GradeAudioPlayer.shared.stop()
        }
    }

    private func close() {
        guard !didClose else { return }
        didClose = true

        GradeAudioPlayer.shared.stop()
        onClose()
    }
}

#Preview("Grade A") { ResultScreen(grade: .a, reason: nil) }
#Preview("Grade B") { ResultScreen(grade: .b, reason: nil) }
#Preview("Grade C") { ResultScreen(grade: .c, reason: nil) }
#Preview("Reject") { ResultScreen(grade: .reject, reason: "Bintik: 24.0% permukaan") }
