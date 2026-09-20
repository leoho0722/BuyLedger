//
//  CurrencyMetadataPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// 在背景 actor 中讀寫支援的幣別資料
@ModelActor
actor CurrencyMetadataPersistence {}

// MARK: - Internal Method

extension CurrencyMetadataPersistence {

    /// 讀出全部幣別代碼，依使用者語言排序
    /// - Returns: ISO 4217 代碼陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAllCodes() throws(PersistenceError) -> [String] {
        let descriptor = FetchDescriptor<CurrencyMetadataRecord>()
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        return records
            .map { $0.code }
            .sorted { left, right in
                left.localizedStandardCompare(right) == .orderedAscending
            }
    }

    /// 讀出快取中最新一筆的更新時間；快取為空時回傳 `nil`
    /// - Returns: 最新更新時間
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func latestUpdate() throws(PersistenceError) -> Date? {
        var descriptor = FetchDescriptor<CurrencyMetadataRecord>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first?.lastUpdated
        }
    }

    /// 以新資料取代快取內容並更新時間
    /// - Parameters:
    ///   - codes: 從 API 取得的 ISO 4217 code 陣列
    ///   - at: 寫入時間
    /// - Throws: 空清單或快取讀寫失敗時拋出 ``CurrencyMetadataPersistenceError``
    /// - Note: 保留防禦性 guard，避免直接呼叫時以空結果進入先刪後寫路徑
    func replace(codes: [String], at: Date) throws(CurrencyMetadataPersistenceError) {
        // 防禦性檢查：空結果不得進入先刪後寫路徑
        guard !codes.isEmpty else {
            throw CurrencyMetadataPersistenceError.emptyCodeList
        }

        do {
            let descriptor = FetchDescriptor<CurrencyMetadataRecord>()
            let records = try PersistenceError.mapFetch {
                try modelContext.fetch(descriptor)
            }
            for record in records {
                modelContext.delete(record)
            }

            for code in codes {
                modelContext.insert(CurrencyMetadataRecord(code: code, lastUpdated: at))
            }

            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw .storage(error)
        }
    }
}
