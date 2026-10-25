//
//  OrderWritesFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 提供訂單寫入測試共用的固定訂單、寫入狀態與編輯草稿
enum OrderWritesFeatureTestSupport {

    // MARK: - Properties

    /// 寫入測試共用的原訂單 (失敗或拒絕時資料應維持此值)
    static let original = LedgerOrder.fixture(id: "O1", status: .confirmed, categories: ["美妝"])

    /// 不參與操作的另一筆訂單
    static let other = LedgerOrder.fixture(id: "OTHER", status: .shipping, categories: ["食品"])
}

// MARK: - Internal Method

extension OrderWritesFeatureTestSupport {

    /// 先設定共用初值，再以同一份引用建立寫入狀態
    ///
    /// - Returns: 含兩筆固定訂單的寫入狀態
    static func makeState() -> OrderWritesFeature.State {
        let orders = Shared<[LedgerOrder]>(value: [])
        orders.withLock {
            $0 = [Self.original, Self.other]
        }
        return OrderWritesFeature.State(orders: orders)
    }

    /// 建立編輯既有訂單的草稿與固定表單識別值
    ///
    /// - Returns: 僅修改備註的編輯狀態
    static func makeEdit() -> OrderEditFeature.State {
        var edit = OrderEditFeature.State(
            original: Self.original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        edit.draft.notes = "已修改"
        return edit
    }

    /// 設定共用初值，讓測試持有與 reducer 相同的訂單引用
    ///
    /// - Parameter orders: 待操作的固定訂單
    /// - Returns: 與測試持有同一份共用引用的寫入狀態
    static func makeCascadeState(orders: [LedgerOrder]) -> OrderWritesFeature.State {
        let sharedOrders = Shared<[LedgerOrder]>(value: [])
        sharedOrders.withLock {
            $0 = orders
        }
        return OrderWritesFeature.State(orders: sharedOrders)
    }
}
