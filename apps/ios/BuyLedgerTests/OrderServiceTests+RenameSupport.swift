//
//  OrderServiceTests+RenameSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Nested Types

extension OrderServiceTests {

    /// 列出參數化測試要逐一執行的五種改名入口
    enum LookupRenameOperation: CaseIterable, Sendable {

        /// 訂單來源改名
        case orderSource

        /// 商品類別改名
        case category

        /// 付款方式改名
        case paymentMethod

        /// 對帳狀態改名
        case reconciliationStatus

        /// 開團名稱改名
        case campaign
    }
}

// MARK: - Internal Method

extension OrderServiceTests {

    /// 為目標空白與未變更的改名測試建立資料
    ///
    /// - Parameter database: 要寫入 fixture 的資料庫
    /// - Returns: 共用訂單
    /// - Throws: 寫入失敗時丟出 `.saveFailed(underlying:)`
    static func seedRenameFixture(
        in database: BuyLedgerDatabase
    ) async throws(PersistenceError) -> LedgerOrder {
        let order = LedgerOrder.fixture(
            id: "ORDER-RENAME-NOOP",
            orderSource: "舊名稱",
            categories: ["舊名稱"],
            paymentMethod: "舊名稱",
            reconciliationStatus: "舊名稱",
            campaignNames: ["舊名稱"],
            photos: [Data([0xA0, 0xA1])]
        )
        try await Self.seed(
            [order],
            categories: ["舊名稱"],
            paymentMethods: [PaymentMethodInfo(name: "舊名稱", flags: .none)],
            database: database
        )
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderSourceRecord(name: "舊名稱"))
            context.insert(ReconciliationStatusRecord(name: "舊名稱"))
        }
        return order
    }

    /// 以固定順序讀取四種查詢主檔名稱
    ///
    /// - Parameter database: 要讀取主檔的資料庫
    /// - Returns: 類別、付款方式、訂單來源、對帳狀態的名稱陣列
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`
    static func fetchRenameMasterNames(
        from database: any BuyLedgerDatabaseProtocol
    ) async throws(PersistenceError) -> [[String]] {
        try await database.read { context throws(PersistenceError) in
            let categories = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<CategoryRecord>()).map(\.name).sorted()
            }
            let paymentMethods = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<PaymentMethodRecord>()).map(\.name).sorted()
            }
            let orderSources = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<OrderSourceRecord>()).map(\.name).sorted()
            }
            let reconciliationStatuses = try PersistenceError.mapFetch {
                try context.fetch(FetchDescriptor<ReconciliationStatusRecord>())
                    .map(\.name)
                    .sorted()
            }
            return [categories, paymentMethods, orderSources, reconciliationStatuses]
        }
    }

    /// 依選擇的 `LookupRenameOperation` 執行改名
    ///
    /// - Parameters:
    ///   - operation: 要執行的 `LookupRenameOperation` 案例
    ///   - oldName: 原本的名稱
    ///   - newName: 尚未去除前後空白的新名稱
    ///   - service: 要呼叫的訂單 Service
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；儲存失敗時丟出 `.saveFailed(underlying:)`
    static func applyRename(
        _ operation: LookupRenameOperation,
        oldName: String,
        newName: String,
        using service: OrderService
    ) async throws(PersistenceError) {
        switch operation {
        case .orderSource:
            try await service.applyOrderSourceRename(oldName, newName)

        case .category:
            try await service.applyCategoryRename(oldName, newName)

        case .paymentMethod:
            try await service.applyPaymentMethodRename(oldName, newName)

        case .reconciliationStatus:
            try await service.applyReconciliationStatusRename(oldName, newName)

        case .campaign:
            try await service.renameOrderCampaign(oldName, newName)
        }
    }
}
