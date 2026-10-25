//
//  OrdersContainerPlanWritesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersContainerPlan` 的單元測試，涵蓋訂單寫入結果對選取、詳情與通知的影響
struct OrdersContainerPlanWritesTests {

    /// 驗證新增訂單且非目前選取時，改選新訂單並通知清單，其餘結果都不觸發
    @Test
    func writeResult_新增訂單且非目前選取_選取新訂單並通知() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "N"),
        ])
        state.list.selectedOrderID = "A"

        // When
        let outcome = OrdersContainerPlan.writeResult(
            .saved(id: "N", isNewOrder: true),
            state: state
        )

        // Then
        #expect(outcome.selection == OrdersWriteOutcome.Selection(orderID: "N", shouldNotify: true))
        #expect(outcome.detailPopIDs.isEmpty)
        #expect(!outcome.shouldPopUnavailableDetails)
        #expect(outcome.closesEditOf == nil)
        #expect(outcome.notice == nil)
    }

    /// 驗證新增訂單已是目前選取時，不改動選取、不發出通知，也不移除詳情
    @Test
    func writeResult_新增訂單已是目前選取_不改變選取() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [LedgerOrder.fixture(id: "N")])
        state.list.selectedOrderID = "N"

        // When
        let outcome = OrdersContainerPlan.writeResult(
            .saved(id: "N", isNewOrder: true),
            state: state
        )

        // Then
        #expect(outcome.selection == nil)
        #expect(outcome.detailPopIDs.isEmpty)
    }

    /// 驗證編輯既有訂單儲存後，清單選取維持不變，也不移除詳情
    @Test
    func writeResult_編輯既有訂單_不改變選取() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        state.list.selectedOrderID = "B"

        // When
        let outcome = OrdersContainerPlan.writeResult(
            .saved(id: "A", isNewOrder: false),
            state: state
        )

        // Then
        #expect(outcome.selection == nil)
        #expect(outcome.detailPopIDs.isEmpty)
    }

    /// 驗證合併完成後，選取合併結果並通知清單，同時移除來源訂單的詳情
    @Test
    func writeResult_合併完成_選取合併結果並移除來源詳情() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "M", mergedSourceIDs: ["A", "B"]),
            LedgerOrder.fixture(id: "C"),
        ])
        state.list.selectedOrderID = "A"

        // When
        let outcome = OrdersContainerPlan.writeResult(.merged(id: "M"), state: state)

        // Then
        #expect(outcome.selection == OrdersWriteOutcome.Selection(orderID: "M", shouldNotify: true))
        #expect(outcome.detailPopIDs == ["A", "B"])
    }

    /// 驗證合併結果已是目前選取時，不發出選取通知，來源訂單的詳情仍會移除
    @Test
    func writeResult_合併結果已是目前選取_不發出選取通知() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "M", mergedSourceIDs: ["A", "B"]),
        ])
        state.list.selectedOrderID = "M"

        // When
        let outcome = OrdersContainerPlan.writeResult(.merged(id: "M"), state: state)

        // Then
        #expect(
            outcome.selection == OrdersWriteOutcome.Selection(orderID: "M", shouldNotify: false)
        )
        #expect(outcome.detailPopIDs == ["A", "B"])
    }

    /// 驗證刪除目前選取的訂單時，改選第一筆可見訂單，並移除該訂單的詳情、關閉其編輯表單
    @Test
    func writeResult_刪除選取中的訂單_改選第一筆並移除詳情與表單() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "B"),
            LedgerOrder.fixture(id: "C"),
        ])
        state.list.selectedOrderID = "A"
        state.list.dateContext = OrderDateContext(
            now: OrdersContainerPlanTestSupport.now,
            calendar: OrdersContainerPlanTestSupport.calendar
        )

        // When
        let outcome = OrdersContainerPlan.writeResult(.deleted("A"), state: state)

        // Then
        #expect(outcome.selection == OrdersWriteOutcome.Selection(orderID: "B", shouldNotify: true))
        #expect(outcome.detailPopIDs == ["A"])
        #expect(outcome.closesEditOf == "A")
    }

    /// 驗證刪除非選取中的訂單時，只移除該訂單的詳情並關閉其編輯表單，清單選取不變
    @Test
    func writeResult_刪除非選取中的訂單_只移除詳情與表單() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        state.list.selectedOrderID = "A"

        // When
        let outcome = OrdersContainerPlan.writeResult(.deleted("C"), state: state)

        // Then
        #expect(outcome.selection == nil)
        #expect(outcome.detailPopIDs == ["C"])
        #expect(outcome.closesEditOf == "C")
    }

    /// 驗證刪除最後一筆可見訂單時，清空選取並通知清單，同時移除該訂單的詳情
    @Test
    func writeResult_刪除最後一筆選取中的訂單_清空選取並通知() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [])
        state.list.selectedOrderID = "A"
        state.list.dateContext = OrderDateContext(
            now: OrdersContainerPlanTestSupport.now,
            calendar: OrdersContainerPlanTestSupport.calendar
        )

        // When
        let outcome = OrdersContainerPlan.writeResult(.deleted("A"), state: state)

        // Then
        #expect(outcome.selection == OrdersWriteOutcome.Selection(orderID: nil, shouldNotify: true))
        #expect(outcome.detailPopIDs == ["A"])
    }

    /// 驗證寫入失敗時，依失敗原因決定是否要求移除已不存在的詳情，並以一次性通知顯示對應訊息
    ///
    /// - Parameter scenario: 寫入失敗案例，含失敗原因、是否移除詳情與通知訊息
    @Test(arguments: WriteFailureCase.allCases)
    func writeResult_寫入失敗_依原因決定是否移除詳情並顯示通知(scenario: WriteFailureCase) {
        // Given
        let state = OrdersContainerPlanTestSupport.makeState(orders: [LedgerOrder.fixture(id: "A")])

        // When
        let outcome = OrdersContainerPlan.writeResult(.failed(scenario.failure), state: state)

        // Then
        let expected = OrdersPresentationFeature.Destination.State.alert(
            Self.expectedWriteFailureAlert(LocalizedStringKey(scenario.message))
        )
        #expect(outcome.shouldPopUnavailableDetails == scenario.shouldPopUnavailableDetails)
        #expect(outcome.notice == expected)
    }
}

// MARK: - Nested Types

extension OrdersContainerPlanWritesTests {

    /// 寫入失敗的測試案例，對應失敗原因、是否移除已不存在的詳情與通知訊息
    struct WriteFailureCase: Sendable {

        /// 合併失敗要移除詳情、刪除失敗不移除的兩種案例
        static let allCases = [
            Self(
                failure: .merge,
                shouldPopUnavailableDetails: true,
                message: "orders.general.message.mergedOrderSaved"
            ),
            Self(
                failure: .delete,
                shouldPopUnavailableDetails: false,
                message: "orders.general.message.orderDeletedTry"
            ),
        ]

        /// 寫入操作回報的失敗原因
        let failure: OrderWriteOperations.Failure

        /// 是否要求移除已不存在的訂單詳情
        let shouldPopUnavailableDetails: Bool

        /// 通知內容的本地化訊息
        let message: String
    }
}

// MARK: - Private Method

private extension OrdersContainerPlanWritesTests {

    /// 建立寫入失敗的一次性通知，只有「知道了」按鈕且訊息為傳入的本地化鍵
    ///
    /// - Parameter message: 通知顯示的本地化訊息
    /// - Returns: `AlertState` 值，標題為固定的本地化鍵
    static func expectedWriteFailureAlert(
        _ message: LocalizedStringKey
    ) -> AlertState<OrdersPresentationFeature.Destination.Alert> {
        AlertState {
            TextState("orders.list.label.operationFailed")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("orders.merge.label.ok")
            }
        } message: {
            TextState(message)
        }
    }
}
