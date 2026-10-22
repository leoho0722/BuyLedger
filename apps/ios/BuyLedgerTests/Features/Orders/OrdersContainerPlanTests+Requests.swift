//
//  OrdersContainerPlanTests+Requests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersContainerPlanTests {

    /// 請求的訂單不存在時不套用任何變更
    @Test
    func fulfill_請求的訂單不存在_回傳none() {
        // Given
        let state = Self.makeState(orders: [LedgerOrder.fixture(id: "A")])
        let context = OrderDateContext(now: Self.now, calendar: Self.calendar)

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .edit("missing"),
            state: state,
            context: context,
            formID: UUID(1)
        )

        // Then
        #expect(Self.isNone(outcome))
    }

    /// 編輯既有訂單缺少表單識別值時不呈現表單
    @Test
    func fulfill_編輯既有訂單缺少表單識別值_回傳none() {
        // Given
        let state = Self.makeState(orders: [LedgerOrder.fixture(id: "A")])
        let context = OrderDateContext(now: Self.now, calendar: Self.calendar)

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .edit("A"),
            state: state,
            context: context,
            formID: nil
        )

        // Then
        #expect(Self.isNone(outcome))
    }

    /// 編輯既有訂單缺少日期脈絡時不呈現表單
    @Test
    func fulfill_編輯既有訂單缺少日期脈絡_回傳none() {
        // Given
        let state = Self.makeState(orders: [LedgerOrder.fixture(id: "A")])

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .edit("A"),
            state: state,
            context: nil,
            formID: UUID(1)
        )

        // Then
        #expect(Self.isNone(outcome))
    }

    /// 發起合併時清單與傳入都沒有日期脈絡，不呈現候選清單
    @Test
    func fulfill_合併可合併訂單兩者皆無日期脈絡_回傳none() {
        // Given
        let state = Self.makeRuleState()

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .merge("A"),
            state: state,
            context: nil,
            formID: nil
        )

        // Then
        #expect(Self.isNone(outcome))
    }

    /// 已合併的訂單不能發起合併，不呈現候選清單
    @Test
    func fulfill_已合併訂單發起合併_回傳none() {
        // Given
        let state = Self.makeRuleState()
        let context = OrderDateContext(now: Self.now, calendar: Self.calendar)

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .merge("M"),
            state: state,
            context: context,
            formID: nil
        )

        // Then
        #expect(Self.isNone(outcome))
    }

    /// 查看詳情的訂單存在時，回傳要推入詳情的訂單識別值
    @Test
    func fulfill_查看詳情訂單存在_回傳推入的識別值() {
        // Given
        let state = Self.makeState(orders: [LedgerOrder.fixture(id: "A")])

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .showDetail("A"),
            state: state,
            context: nil,
            formID: nil
        )

        // Then
        #expect(Self.shownOrderID(outcome) == "A")
    }

    /// 查看詳情的訂單不存在時不推入詳情
    @Test
    func fulfill_查看詳情訂單不存在_回傳none() {
        // Given
        let state = Self.makeState(orders: [LedgerOrder.fixture(id: "A")])

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .showDetail("missing"),
            state: state,
            context: nil,
            formID: nil
        )

        // Then
        #expect(Self.isNone(outcome))
    }

    /// 單筆狀態變更轉為寫入子層的狀態請求，容器不直接改寫訂單
    @Test
    func fulfill_單筆狀態變更_轉送寫入子層的請求() {
        // Given
        let state = Self.makeState(orders: [LedgerOrder.fixture(id: "A")])

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .changeStatus(id: "A", status: .shipping),
            state: state,
            context: nil,
            formID: nil
        )

        // Then
        #expect(Self.isStatusChangeRequest(outcome, id: "A", status: .shipping))
    }

    /// 批次狀態變更轉為寫入子層的批次請求，內容保留已選訂單
    @Test
    func fulfill_批次狀態變更_轉送寫入子層的請求() {
        // Given
        let order = LedgerOrder.fixture(id: "A")
        let state = Self.makeState(orders: [order])

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .batchStatusChange([order]),
            state: state,
            context: nil,
            formID: nil
        )

        // Then
        #expect(Self.isBatchStatusChangeRequest(outcome, orders: [order]))
    }
}

// MARK: - Private Method

private extension OrdersContainerPlanTests {

    /// 判斷請求結果是否為不套用任何變更
    ///
    /// - Parameter outcome: 容器請求的套用結果
    /// - Returns: 結果為 `.none` 時為 `true`
    static func isNone(_ outcome: OrdersRequestOutcome) -> Bool {
        guard case .none = outcome else {
            return false
        }
        return true
    }

    /// 取出要推入詳情的訂單識別值，其他結果為 `nil`
    ///
    /// - Parameter outcome: 容器請求的套用結果
    /// - Returns: 要推入詳情的訂單識別值
    static func shownOrderID(_ outcome: OrdersRequestOutcome) -> LedgerOrder.ID? {
        guard case .showDetail(let id) = outcome else {
            return nil
        }
        return id
    }

    /// 判斷結果是否為指定訂單與狀態的單筆狀態變更寫入請求
    ///
    /// - Parameters:
    ///   - outcome: 容器請求的套用結果
    ///   - id: 訂單識別值
    ///   - status: 新狀態
    /// - Returns: 結果是對應的單筆狀態變更寫入請求時為 `true`
    static func isStatusChangeRequest(
        _ outcome: OrdersRequestOutcome,
        id: LedgerOrder.ID,
        status: OrderStatus
    ) -> Bool {
        guard case .write(.statusChangeRequested(let actualID, let actualStatus)) = outcome else {
            return false
        }
        return actualID == id && actualStatus == status
    }

    /// 判斷結果是否為指定訂單清單的批次狀態變更寫入請求
    ///
    /// - Parameters:
    ///   - outcome: 容器請求的套用結果
    ///   - orders: 預期的已選訂單
    /// - Returns: 結果是對應的批次狀態變更寫入請求時為 `true`
    static func isBatchStatusChangeRequest(
        _ outcome: OrdersRequestOutcome,
        orders: [LedgerOrder]
    ) -> Bool {
        guard case .write(.batchStatusChangeRequested(let changed)) = outcome else {
            return false
        }
        return changed == orders
    }
}
