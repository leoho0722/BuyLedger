//
//  CurrencyMetadataPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 上對「支援幣別主檔」做讀寫的背景 actor
///
/// 每次 ``replace(codes:at:)`` 會把舊 cache 全部刪掉再寫入新的，符合「API 是 source of truth」的設計：API 對某 code 已停止支援時，本地 cache 也應跟著消失
@ModelActor
actor CurrencyMetadataPersistence {

    // MARK: - View Method

    /// 讀出全部 code，依 locale 升冪排序
    /// - Returns: ISO 4217 code 陣列
    func fetchAllCodes() throws -> [String] {
        let descriptor = FetchDescriptor<CurrencyMetadataRecord>()
        let records = try modelContext.fetch(descriptor)
        return records
            .map { $0.code }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    /// 讀出 cache 中最新一筆的更新時間；空 cache 時回 `nil`
    /// - Returns: 最新更新時間
    func latestUpdate() throws -> Date? {
        var descriptor = FetchDescriptor<CurrencyMetadataRecord>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.lastUpdated
    }

    /// 整批替換 cache 內容：刪光舊資料、寫入新 codes、共用同一個 `lastUpdated`
    /// - Parameters:
    ///   - codes: 從 API 取得的 ISO 4217 code 陣列
    ///   - at: 寫入時間，會被填入所有 record 的 ``CurrencyMetadataRecord/lastUpdated``
    func replace(codes: [String], at: Date) throws {
        let descriptor = FetchDescriptor<CurrencyMetadataRecord>()
        for record in try modelContext.fetch(descriptor) {
            modelContext.delete(record)
        }

        for code in codes {
            modelContext.insert(CurrencyMetadataRecord(code: code, lastUpdated: at))
        }

        try modelContext.save()
    }
}
