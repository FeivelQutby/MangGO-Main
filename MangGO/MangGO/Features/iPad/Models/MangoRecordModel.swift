//
//  MangoRecordModel.swift
//  MangGO
//

import Foundation
import SwiftUI

/// Data model untuk catatan hasil grading mangga (historis & real-time).
struct MangoRecord: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let grade: GradeDisplay
    let weightGrams: Double
    let volumeCm3: Double
    let blushPercent: Double
    let defectPercent: Double
    let rejectionReason: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        grade: GradeDisplay,
        weightGrams: Double,
        volumeCm3: Double,
        blushPercent: Double,
        defectPercent: Double,
        rejectionReason: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.grade = grade
        self.weightGrams = weightGrams
        self.volumeCm3 = volumeCm3
        self.blushPercent = blushPercent
        self.defectPercent = defectPercent
        self.rejectionReason = rejectionReason
    }

    var formattedCode: String {
        let suffix = abs(id.uuidString.hashValue % 900) + 100
        return "R48-\(suffix)"
    }

    var weightStatus: String {
        weightGrams >= 351 ? "memenuhi standar" : "tidak memenuhi standar"
    }

    var defectStatus: String {
        defectPercent > 15 ? "defect tinggi" : "defect normal"
    }
}

/// Helper data dummy untuk visualisasi dashboard & riwayat (30 hari terakhir).
@MainActor
enum DummyDataStore {

    static func generateDummyRecords() -> [MangoRecord] {
        var records: [MangoRecord] = []
        let calendar = Calendar.current
        
        // Define exact target date: August 13, 2026
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 13
        guard let anchorDate = calendar.date(from: components) else { return [] }

        // Generate data for the past 150 days to cover full 3 previous months
        for dayOffset in 0..<150 {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: anchorDate) else { continue }
            
            let countForDay = Int.random(in: 10...30)
            
            for _ in 0..<countForDay {
                let minute = Int.random(in: 0...59)
                let hour = Int.random(in: 8...17)
                var recordComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
                recordComponents.hour = hour
                recordComponents.minute = minute
                guard let recordDate = calendar.date(from: recordComponents) else { continue }

                // Distribusi Grade: A (35%), B (30%), C (25%), Reject (10%)
                let roll = Int.random(in: 1...100)
                let grade: GradeDisplay
                let weight: Double
                let volume: Double
                let blush: Double
                let defect: Double
                let reason: String?

                if roll <= 35 {
                    grade = .a
                    weight = Double.random(in: 410...550)
                    volume = Double.random(in: 360...520)
                    blush = Double.random(in: 16...38)
                    defect = Double.random(in: 0.5...4.5)
                    reason = nil
                } else if roll <= 65 {
                    grade = .b
                    weight = Double.random(in: 355...400)
                    volume = Double.random(in: 285...345)
                    blush = Double.random(in: 6...14.5)
                    defect = Double.random(in: 5.5...14.5)
                    reason = "Bintik permukaan 8.5%"
                } else if roll <= 90 {
                    grade = .c
                    weight = Double.random(in: 280...350)
                    volume = Double.random(in: 210...279)
                    blush = Double.random(in: 1...4.8)
                    defect = Double.random(in: 15.5...28.0)
                    reason = "Volume di bawah standar (240 cm³)"
                } else {
                    grade = .reject
                    weight = Double.random(in: 180...270)
                    volume = Double.random(in: 150...200)
                    blush = Double.random(in: 0...0.8)
                    defect = Double.random(in: 31.0...45.0)
                    reason = "Bintik permukaan melebihi ambang (34.2%)"
                }

                records.append(
                    MangoRecord(
                        timestamp: recordDate,
                        grade: grade,
                        weightGrams: weight,
                        volumeCm3: volume,
                        blushPercent: blush,
                        defectPercent: defect,
                        rejectionReason: reason
                    )
                )
            }
        }
        return records.sorted(by: { $0.timestamp > $1.timestamp })
    }
}
