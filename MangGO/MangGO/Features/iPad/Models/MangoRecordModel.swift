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
    let defectPercent: Double
    let rejectionReason: String?
    let recordCode: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        grade: GradeDisplay,
        weightGrams: Double,
        defectPercent: Double,
        rejectionReason: String? = nil,
        recordCode: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.grade = grade
        self.weightGrams = weightGrams
        self.defectPercent = defectPercent
        self.rejectionReason = rejectionReason
        self.recordCode = recordCode
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case grade
        case weightGrams
        case defectPercent
        case rejectionReason
        case recordCode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        grade = try container.decode(GradeDisplay.self, forKey: .grade)
        weightGrams = try container.decode(Double.self, forKey: .weightGrams)
        defectPercent = try container.decode(Double.self, forKey: .defectPercent)
        rejectionReason = try container.decodeIfPresent(String.self, forKey: .rejectionReason)
        recordCode = try container.decodeIfPresent(String.self, forKey: .recordCode) ?? ""
    }
    
    func withRecordCode(_ recordCode: String) -> MangoRecord {
        MangoRecord(
            id: id,
            timestamp: timestamp,
            grade: grade,
            weightGrams: weightGrams,
            defectPercent: defectPercent,
            rejectionReason: rejectionReason,
            recordCode: recordCode
        )
    }

    var formattedCode: String {
        if !recordCode.isEmpty {
            return recordCode
        }
        
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

    static func generateDummyRecords(days: Int = 30) -> [MangoRecord] {
        var records: [MangoRecord] = []
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            // Variasi jumlah mangga per hari (60 s/d 140 mangga per hari)
            let countForDay = Int.random(in: 60...140)
            
            for _ in 0..<countForDay {
                let minute = Int.random(in: 0...59)
                let hour = Int.random(in: 8...17)
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = minute
                guard let recordDate = calendar.date(from: components) else { continue }

                // Distribusi Grade: A (35%), B (30%), C (25%), Reject (10%)
                let roll = Int.random(in: 1...100)
                let grade: GradeDisplay
                let weight: Double
                let defect: Double
                let reason: String?

                if roll <= 35 {
                    grade = .a
                    weight = Double.random(in: 410...550)
                    defect = Double.random(in: 0.5...4.5)
                    reason = nil
                } else if roll <= 65 {
                    grade = .b
                    weight = Double.random(in: 355...400)
                    defect = Double.random(in: 5.5...14.5)
                    reason = "Bintik permukaan 8.5%"
                } else if roll <= 90 {
                    grade = .c
                    weight = Double.random(in: 280...350)
                    defect = Double.random(in: 15.5...28.0)
                    reason = "Volume di bawah standar (240 cm³)"
                } else {
                    grade = .reject
                    weight = Double.random(in: 180...270)
                    defect = Double.random(in: 31.0...45.0)
                    reason = "Bintik permukaan melebihi ambang (34.2%)"
                }

                records.append(
                    MangoRecord(
                        timestamp: recordDate,
                        grade: grade,
                        weightGrams: weight,
                        defectPercent: defect,
                        rejectionReason: reason
                    )
                )
            }
        }
        return records.sorted(by: { $0.timestamp > $1.timestamp })
    }
}
