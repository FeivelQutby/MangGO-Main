//
//  MangoRecordStore.swift
//  MangGO
//
//  Created by Feivel Qutby on 17/08/26.
//


import Foundation
import Observation

@MainActor
@Observable
final class MangoRecordStore {

    private(set) var records: [MangoRecord] = []

    private let storageKey = "manggo.mangoRecords"

    init() {
        load()
    }

    // MARK: - Add

    func add(_ record: MangoRecord) {
        // Prevent duplicate records
        guard !records.contains(where: { $0.id == record.id }) else {
            return
        }

        let recordToSave = record.recordCode.isEmpty
        ? record.withRecordCode(nextRecordCode(for: record.timestamp))
        : record

        records.append(recordToSave)

        // Newest first
        records.sort {
            $0.timestamp > $1.timestamp
        }

        save()
    }

    // MARK: - Record Code

    private func nextRecordCode(for date: Date) -> String {
        let calendar = Calendar.current
        let sequence = records.filter {
            calendar.isDate($0.timestamp, inSameDayAs: date)
        }.count + 1

        return Self.recordCode(for: date, sequence: sequence)
    }

    private static func recordCode(for date: Date, sequence: Int) -> String {
        let components = Calendar.current.dateComponents([.month, .day], from: date)
        return String(
            format: "M%d%d-%03d",
            components.month ?? 0,
            components.day ?? 0,
            sequence
        )
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save mango records:", error)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            records = try JSONDecoder().decode(
                [MangoRecord].self,
                from: data
            )
            migrateMissingRecordCodes()
        } catch {
            print("❌ Failed to load mango records:", error)
            records = []
        }
    }

    private func migrateMissingRecordCodes() {
        var migratedRecords: [MangoRecord] = []
        var dailySequences: [Date: Int] = [:]
        var didMigrate = false
        let calendar = Calendar.current

        for record in records.sorted(by: { $0.timestamp < $1.timestamp }) {
            let startOfDay = calendar.startOfDay(for: record.timestamp)
            let sequence = dailySequences[startOfDay, default: 0] + 1
            dailySequences[startOfDay] = sequence

            if record.recordCode.isEmpty {
                didMigrate = true
                migratedRecords.append(
                    record.withRecordCode(Self.recordCode(for: record.timestamp, sequence: sequence))
                )
            } else {
                migratedRecords.append(record)
            }
        }

        records = migratedRecords.sorted(by: { $0.timestamp > $1.timestamp })
        if didMigrate {
            save()
        }
    }

    // MARK: - Debug

    func clearAll() {
        records.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
