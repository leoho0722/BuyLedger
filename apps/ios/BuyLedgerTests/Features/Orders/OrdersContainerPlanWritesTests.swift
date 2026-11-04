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

/// `OrdersContainerPlan` 的單元測試，涵蓋訂單寫入結果對詳情與通知的影響
struct OrdersContainerPlanWritesTests {

    /// 驗證新增訂單存檔後不自動開啟詳情或顯示通知
    @Test
    func writeResult_新增訂單存檔_不自動開啟詳情() {
        // Given
        let state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "N"),
        ])

        // When
        let outcome = OrdersContainerPlan.writeResult(
            .saved(id: "N", isNewOrder: true),
            state: state
        )

        // Then
        #expect(outcome.detailPopIDs.isEmpty)
        #expect(!outcome.shouldPopUnavailableDetails)
        #expect(outcome.closesEditOf == nil)
        #expect(outcome.notice == nil)
    }

    /// 驗證新增訂單存檔時，保留既有詳情路徑
    @Test
    func writeResult_新增訂單存檔_保留既有詳情path() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [LedgerOrder.fixture(id: "N")])
        state.detail.showDetail(orderID: "N")
        let pathIDsBefore = Array(state.detail.path.ids)

        // When
        let outcome = OrdersContainerPlan.writeResult(
            .saved(id: "N", isNewOrder: true),
            state: state
        )

        // Then
        #expect(outcome.detailPopIDs.isEmpty)
        #expect(Array(state.detail.path.ids) == pathIDsBefore)
    }

    /// 驗證編輯既有訂單儲存後，保留目前詳情路徑
    @Test
    func writeResult_編輯既有訂單_保留目前詳情path() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        state.detail.showDetail(orderID: "B")
        let pathIDsBefore = Array(state.detail.path.ids)

        // When
        let outcome = OrdersContainerPlan.writeResult(
            .saved(id: "A", isNewOrder: false),
            state: state
        )

        // Then
        #expect(outcome.detailPopIDs.isEmpty)
        #expect(Array(state.detail.path.ids) == pathIDsBefore)
    }

    /// 驗證合併完成後只標記來源訂單詳情移除
    @Test
    func writeResult_合併完成_標記來源詳情移除() {
        // Given
        let state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "M", mergedSourceIDs: ["A", "B"]),
            LedgerOrder.fixture(id: "C"),
        ])

        // When
        let outcome = OrdersContainerPlan.writeResult(.merged(id: "M"), state: state)

        // Then
        #expect(outcome.detailPopIDs == ["A", "B"])
    }

    /// 驗證合併結果已有詳情路徑時，只標記合併來源移除
    @Test
    func writeResult_合併結果已有詳情path_標記來源詳情移除() {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "M", mergedSourceIDs: ["A", "B"]),
        ])
        state.detail.showDetail(orderID: "M")

        // When
        let outcome = OrdersContainerPlan.writeResult(.merged(id: "M"), state: state)

        // Then
        #expect(outcome.detailPopIDs == ["A", "B"])
    }

    /// 驗證刪除訂單後，要求移除詳情並關閉該訂單表單
    @Test
    func writeResult_刪除訂單_移除詳情並關閉表單() {
        // Given
        let state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "B"),
            LedgerOrder.fixture(id: "C"),
        ])

        // When
        let outcome = OrdersContainerPlan.writeResult(.deleted("A"), state: state)

        // Then
        #expect(outcome.detailPopIDs == ["A"])
        #expect(outcome.closesEditOf == "A")
    }

    /// 驗證寫入失敗時，依失敗原因決定是否移除已不存在的詳情
    /// 並以一次性通知顯示對應訊息
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
