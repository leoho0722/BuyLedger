//
//  VerificationStatusPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import Foundation
import SwiftData

/// SwiftData 上對對帳狀態主檔做 CRUD 的背景 actor
@ModelActor
actor VerificationStatusPersistence {}

// MARK: - Internal Method

extension VerificationStatusPersistence {

    /// 讀出全部對帳狀態名稱，依 locale 升冪排序
    /// - Returns: 對帳狀態名稱陣列
    func fetchAll() throws -> [String] {
        let descriptor = FetchDescriptor<VerificationStatusRecord>()
        let records = try modelContext.fetch(descriptor)
        return records
            .map { $0.name }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    /// 寫入指定名稱的對帳狀態；若已存在不重複建立
    /// - Parameter name: 對帳狀態名稱 (呼叫前由 caller 完成 trim)
    func upsert(name: String) throws {
        let descriptor = FetchDescriptor<VerificationStatusRecord>(
            predicate: #Predicate { $0.name == name }
        )

        if try modelContext.fetch(descriptor).first == nil {
            modelContext.insert(VerificationStatusRecord(name: name))
            try modelContext.save()
        }
    }

    /// 刪除指定名稱的對帳狀態；不存在時視為 no-op
    /// - Parameter name: 對帳狀態名稱
    func delete(name: String) throws {
        let descriptor = FetchDescriptor<VerificationStatusRecord>(
            predicate: #Predicate { $0.name == name }
        )

        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }

        try modelContext.save()
    }

    /// 將指定對帳狀態更名；若新名稱已存在則合併 (刪除舊紀錄即可)，訂單端的 cascade 由 caller 另外處理
    /// - Parameters:
    ///   - oldName: 原本的對帳狀態名稱
    ///   - newName: 新的對帳狀態名稱 (由 caller 完成 trim)
    func rename(from oldName: String, to newName: String) throws {
        let oldDescriptor = FetchDescriptor<VerificationStatusRecord>(
            predicate: #Predicate { $0.name == oldName }
        )
        for record in try modelContext.fetch(oldDescriptor) {
            modelContext.delete(record)
        }

        let newDescriptor = FetchDescriptor<VerificationStatusRecord>(
            predicate: #Predicate { $0.name == newName }
        )
        if try modelContext.fetch(newDescriptor).first == nil {
            modelContext.insert(VerificationStatusRecord(name: newName))
        }

        try modelContext.save()
    }
}
