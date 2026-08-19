//
//  iPadView.swift
//  MangGO
//
//  Created by Feivel Qutby on 07/08/26.
//

import SwiftUI

/// Shell layar iPad: hanya mengurus pemilihan tab dan overlay hasil.
/// Isi tiap tab ada di `Grading/GradingScreen.swift` dan
/// `Dashboard/DashboardScreen.swift`.
struct iPadView: View {

    enum Tab: String, CaseIterable {
        case grading = "Grading"
        case dataHarian = "Data Harian"
        case tren = "Tren"
    }

    @Environment(StationSync.self) private var sync
    @State private var tab: Tab = .grading

    /// Hasil terakhir yang sudah ditutup operator (atau ditutup sendiri oleh
    /// timer di `ResultScreen`). Snapshot dari iPhone tetap bertahan di fase
    /// `.done` sampai buah berikutnya masuk, jadi tanpa penanda ini overlay akan
    /// langsung muncul lagi begitu ditutup. Dikunci ke id hasil supaya buah
    /// berikutnya — yang id-nya berbeda — tetap memunculkan layar hasilnya.
    @State private var dismissedResultID: UUID?

    // DUMMY DATA
    @State private var dummyRecords: [MangoRecord] = DummyDataStore.generateDummyRecords()
    // REAL DATA (Pilih salah satu)
    @State private var recordStore = MangoRecordStore()
    
    private var realRecords: [MangoRecord] {
        recordStore.records
    }

    private var snapshot: StationSnapshot { sync.snapshot }

    private var finishedGrade: GradeDisplay? {
        sync.isLinked ? snapshot.completedGrade : nil
    }

    /// Hasil yang layar penuhnya masih layak ditampilkan: sudah selesai, belum
    /// ditutup, dan tab Grading sedang aktif.
    private var activeResult: StationSnapshot.Result? {
        guard tab == .grading,
              finishedGrade != nil,
              let result = snapshot.lastResult,
              result.id != dismissedResultID
        else { return nil }

        return result
    }

    private var todayRecords: [MangoRecord] {
        let calendar = Calendar.current
        let today = Date()
        return dummyRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }
    
    private var records: [MangoRecord] {
        recordStore.records
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Navigation Bar matching Figma
                ZStack {
                    // Center: Main Tab Picker
                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 420)

                    // Trailing: Sub-preset picker & Debug Toggle
                        Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))

                Divider()

                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Layar hasil hanya menutupi tab Grading.
            if let result = activeResult, let grade = finishedGrade {
                ResultScreen(grade: grade, reason: result.reason) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        dismissedResultID = result.id
                    }
                }
                // Tanpa `.id` SwiftUI memakai ulang view yang sama untuk buah
                // berikutnya: `.task` tidak dijalankan ulang, sehingga suara
                // tidak berbunyi lagi dan timer 5 detik tidak dimulai ulang.
                .id(result.id)
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: snapshot.phase)
        .onChange(of: snapshot.lastResult?.id) { _, _ in
                saveLatestResult()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .grading:
            GradingScreen(snapshot: snapshot,
                          isLinked: sync.isLinked,
                          connectionError: sync.lastError)

//        DUMMY DATA
//        case .dataHarian:
//            if dummyRecords.isEmpty {
//                EmptyStateView(
//                    title: "Belum Ada Data Harian Grading",
//                    subtitle: "Mulai batch baru untuk melihat data harian grading",
//                    icon: "shippingbox"
//                )
//            } else {
//                RecentScreen(records: dummyRecords)
//            }
            
//      REAL DATA (Pilih salah satu)
        case .dataHarian:
            if realRecords.isEmpty {
                EmptyStateView(
                    title: "Belum Ada Data Harian Grading",
                    subtitle: "Mulai batch baru untuk melihat data harian grading",
                    icon: "shippingbox"
                )
            } else {
                RecentScreen(records: realRecords)
            }

        case .tren:
            HistoryScreen(allRecords: dummyRecords)
            
//        case .tren:
//            if records.isEmpty {
//                EmptyStateView(
//                    title: "Belum Ada Data Tren Grading",
//                    subtitle: "Mulai batch baru untuk melihat data tren grading",
//                    icon: "shippingbox"
//                )
//            } else {
//                HistoryScreen(allRecords: records)
//            }
        }
    }
    
    private func saveLatestResult() {
        guard snapshot.phase == .done,
              let result = snapshot.lastResult,
              let grade = GradeDisplay(rawValue: result.grade)
        else {
            return
        }

        let record = MangoRecord(
            id: result.id,
            timestamp: result.gradedAt,
            grade: grade,
            weightGrams: result.weightGrams ?? 0,
            defectPercent: result.defectPercent ?? 0,
            rejectionReason: result.reason
        )

        recordStore.add(record)

        // Simpan foto dokumentasi kalau ada (hanya reject yang mengirimnya).
        // Dikunci id yang sama dengan record supaya `RejectedMangoDetailView`
        // bisa memuatnya kembali lewat `MangoImageStore`.
        if result.imageA != nil || result.imageB != nil {
            MangoImageStore.shared.save(
                id: result.id,
                sideA: result.imageA,
                sideB: result.imageB
            )
        } else if grade == .reject {
            print("⚠️ Hasil reject \(result.id) datang tanpa foto sisi mana pun")
        }
    }
}

#Preview {
    iPadView().environment(StationSync(role: .display))
}

