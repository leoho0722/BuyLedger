//
//  OrdersContainerPlanTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// `OrdersContainerPlan` 系列測試共用的固定時間、`OrdersFeature` 狀態建立與表單目的地查詢
enum OrdersContainerPlanTestSupport {

    // MARK: - Properties

    /// 測試用的固定現在時間 (表單與訂單日期的基準)
    static let now = Date(timeIntervalSince1970: 1_780_000_000)

    /// 測試用的固定行事曆 (與 `now` 組成日期脈絡)
    static let calendar = TestDependencies.fixedCalendar
}

// MARK: - Internal Method

extension OrdersContainerPlanTestSupport {

    /// 建立含可合併、已合併與已取消訂單各一筆的 `OrdersFeature` 狀態，供資格判斷的參數化測試共用
    ///
    /// - Returns: 訂單 A 可合併、M 已合併、X 已取消的 `OrdersFeature` 狀態
    static func makeRuleState() -> OrdersFeature.State {
        OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "M", status: .merged),
            LedgerOrder.fixture(id: "X", status: .cancelled),
        ])
    }

    /// 以獨立的記憶體儲存建立 `OrdersFeature` 狀態，主檔與幣別不會外溢到其他測試
    ///
    /// - Parameter orders: 初始狀態要放入的訂單
    /// - Returns: `OrdersFeature` 的初始狀態
    static func makeState(orders: [LedgerOrder]) -> OrdersFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State(orders: orders)
        }
    }

    /// 取出表單目的地中的訂單編輯狀態，其他種類的目的地為 `nil`
    ///
    /// - Parameter destination: 要查詢的呈現目的地
    /// - Returns: 訂單編輯表單的狀態
    static func editState(
        of destination: OrdersPresentationFeature.Destination.State
    ) -> OrderEditFeature.State? {
        guard case .edit(let edit) = destination else {
            return nil
        }
        return edit
    }
}
