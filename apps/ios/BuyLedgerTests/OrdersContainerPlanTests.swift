//
//  OrdersContainerPlanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// 驗證 `OrdersContainerPlan` 的表單識別值與日期脈絡判斷，以及請求、寫入結果與表單計畫的回傳值
struct OrdersContainerPlanTests {

    // MARK: - Properties

    /// 測試用的固定現在時間，表單與訂單的日期都以此為基準
    static let now = Date(timeIntervalSince1970: 1_780_000_000)

    /// 測試用的固定行事曆，與 `now` 搭配建立日期脈絡
    static let calendar = TestDependencies.fixedCalendar
}

extension OrdersContainerPlanTests {

    /// 新增與有效編輯需要表單識別值，合併、刪除、查看詳情與狀態變更等請求不需要
    ///
    /// - Parameters:
    ///   - request: 清單或詳情的操作請求
    ///   - isFormIDRequired: 新增，或編輯的訂單存在時為真，其餘請求為假
    @Test(arguments: [
        (OrderRequest.create, true),
        (OrderRequest.edit("A"), true),
        (OrderRequest.edit("missing"), false),
        (OrderRequest.merge("A"), false),
        (OrderRequest.delete("A"), false),
        (OrderRequest.showDetail("A"), false),
        (OrderRequest.batchStatusChange([LedgerOrder.fixture(id: "A")]), false),
        (OrderRequest.changeStatus(id: "A", status: .shipping), false),
        (OrderRequest.aiSummary, false),
    ])
    func requiresFormID_請求種類_依規則決定是否需要表單識別值(request: OrderRequest, isFormIDRequired: Bool) {
        // Given
        let state = Self.makeState(orders: [LedgerOrder.fixture(id: "A")])

        // When
        let isRequired = OrdersContainerPlan.requiresFormID(request, state: state)

        // Then
        #expect(isRequired == isFormIDRequired)
    }

    /// 新增與有效編輯需要日期脈絡，合併只在可合併且清單尚未記錄日期時需要，其餘請求不需要
    ///
    /// - Parameters:
    ///   - request: 清單或詳情的操作請求
    ///   - isDateContextRequired: 該請求是否需要由 reducer 解析日期脈絡
    @Test(arguments: [
        (OrderRequest.create, true),
        (OrderRequest.edit("A"), true),
        (OrderRequest.edit("missing"), false),
        (OrderRequest.merge("A"), true),
        (OrderRequest.merge("M"), false),
        (OrderRequest.merge("X"), false),
        (OrderRequest.merge("missing"), false),
        (OrderRequest.delete("A"), false),
        (OrderRequest.showDetail("A"), false),
        (OrderRequest.batchStatusChange([LedgerOrder.fixture(id: "A")]), false),
        (OrderRequest.changeStatus(id: "A", status: .shipping), false),
        (OrderRequest.aiSummary, false),
    ])
    func requiresDateContext_請求種類_依規則決定是否需要日期脈絡(
        request: OrderRequest,
        isDateContextRequired: Bool
    ) {
        // Given
        let state = Self.makeRuleState()

        // When
        let isRequired = OrdersContainerPlan.requiresDateContext(request, state: state)

        // Then
        #expect(isRequired == isDateContextRequired)
    }

    /// 清單已記錄日期脈絡時，合併不需要再由 reducer 解析時間與行事曆
    @Test
    func requiresDateContext_清單已有日期脈絡_合併不需要() {
        // Given
        var state = Self.makeRuleState()
        state.list.dateContext = OrderDateContext(now: Self.now, calendar: Self.calendar)

        // When
        let isRequired = OrdersContainerPlan.requiresDateContext(.merge("A"), state: state)

        // Then
        #expect(isRequired == false)
    }
}

// MARK: - Internal Method

extension OrdersContainerPlanTests {

    /// 建立含可合併、已合併與已取消訂單的快照，供資格判斷的參數化測試共用
    ///
    /// - Returns: 訂單 A 可合併、M 已合併、X 已取消的容器快照
    static func makeRuleState() -> OrdersFeature.State {
        makeState(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "M", status: .merged),
            LedgerOrder.fixture(id: "X", status: .cancelled),
        ])
    }

    /// 以獨立的記憶體儲存建立容器快照，主檔與幣別不會外溢到其他測試
    ///
    /// - Parameter orders: 容器共用的訂單
    /// - Returns: 容器的初始快照
    static func makeState(orders: [LedgerOrder]) -> OrdersFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State(orders: orders)
        }
    }

    /// 取出表單目的地中的訂單編輯狀態，其他種類的目的地為 `nil`
    ///
    /// - Parameter destination: 容器要呈現的目的地
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
