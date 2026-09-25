//
//  OrderPersistence+LookupTesting.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/25.
//

import Foundation
import SwiftData

@testable import BuyLedger

// MARK: - Internal Method

extension OrderPersistence {

    /// 從目前的 persistence context 讀取名稱主檔，供原子改名測試檢查 context 狀態
    ///
    /// - Parameter recordType: 要讀取的主檔記錄型別
    /// - Returns: 主檔名稱
    /// - Throws: 查詢失敗時拋出 `PersistenceError.fetchFailed`
    func fetchLookupNamesForTesting<Record: NameLookupRecordProtocol>(
        of recordType: Record.Type
    ) throws(PersistenceError) -> [String] {
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(FetchDescriptor<Record>())
        }
        return records.map(\.name)
    }

    /// 從目前的 context 讀取付款方式旗標，供 stale read 測試建立初始快照
    ///
    /// - Returns: 付款方式資料
    /// - Throws: 查詢失敗時拋出 `PersistenceError.fetchFailed`
    func fetchPaymentMethodInfosForTesting() throws(PersistenceError) -> [PaymentMethodInfo] {
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(FetchDescriptor<PaymentMethodRecord>())
        }
        return records.map { record in
            PaymentMethodInfo(
                name: record.name,
                flags: PaymentMethodFlags(
                    isCardless: record.isCardless,
                    isBankTransfer: record.isBankTransfer,
                    isCashOnDelivery: record.isCashOnDelivery
                )
            )
        }
    }
}
