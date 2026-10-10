//
//  OrdersContainerPlanTests+Writes.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersContainerPlanTests {

    /// 新增訂單且不是目前選取時，改選新訂單並通知清單，其餘結果保持空白
    @Test
    func writeResult_新增訂單且非目前選取_選取新訂單並通知() {
        // Given
        var state = Self.makeState(orders: [
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
        #expect(outcome.addedOption == nil)
        #expect(outcome.notice == nil)
    }

    /// 新增訂單已是目前選取時不改動選取，也不發出通知
    @Test
    func writeResult_新增訂單已是目前選取_不改變選取() {
        // Given
        var state = Self.makeState(orders: [LedgerOrder.fixture(id: "N")])
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

    /// 編輯既有訂單儲存後不改變清單選取
    @Test
    func writeResult_編輯既有訂單_不改變選取() {
        // Given
        var state = Self.makeState(orders: [
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

    /// 合併完成後選取合併結果，並移除來源訂單的詳情
    @Test
    func writeResult_合併完成_選取合併結果並移除來源詳情() {
        // Given
        var state = Self.makeState(orders: [
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

    /// 合併結果已是目前選取時不發出選取通知，來源詳情仍會移除
    @Test
    func writeResult_合併結果已是目前選取_不發出選取通知() {
        // Given
        var state = Self.makeState(orders: [
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

    /// 新增主檔選項成功時回傳待寫回來源表單的選項計畫，不改變清單選取
    @Test
    func writeResult_新增主檔選項_回傳待寫回表單的計畫() {
        // Given
        let state = Self.makeState(orders: [])
        let flags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let plan = OrderOptionWritePlan(
            formID: UUID(5),
            kind: .category,
            name: "新類別",
            flags: flags
        )

        // When
        let outcome = OrdersContainerPlan.writeResult(.optionAdded(plan), state: state)

        // Then
        #expect(outcome.addedOption?.formID == UUID(5))
        #expect(outcome.addedOption?.kind == .category)
        #expect(outcome.addedOption?.name == "新類別")
        #expect(outcome.addedOption?.flags.isCardless == true)
        #expect(outcome.selection == nil)
    }

    /// 刪除目前選取的訂單時改選第一筆可見訂單，並移除詳情與正在編輯的表單
    @Test
    func writeResult_刪除選取中的訂單_改選第一筆並移除詳情與表單() {
        // Given
        var state = Self.makeState(orders: [
            LedgerOrder.fixture(id: "B"),
            LedgerOrder.fixture(id: "C"),
        ])
        state.list.selectedOrderID = "A"
        state.list.dateContext = OrderDateContext(now: Self.now, calendar: Self.calendar)

        // When
        let outcome = OrdersContainerPlan.writeResult(.deleted("A"), state: state)

        // Then
        #expect(outcome.selection == OrdersWriteOutcome.Selection(orderID: "B", shouldNotify: true))
        #expect(outcome.detailPopIDs == ["A"])
        #expect(outcome.closesEditOf == "A")
    }

    /// 刪除非選取中的訂單只移除詳情與表單，不改變清單選取
    @Test
    func writeResult_刪除非選取中的訂單_只移除詳情與表單() {
        // Given
        var state = Self.makeState(orders: [
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

    /// 刪除最後一筆可見訂單時清空選取，並通知清單
    @Test
    func writeResult_刪除最後一筆選取中的訂單_清空選取並通知() {
        // Given
        var state = Self.makeState(orders: [])
        state.list.selectedOrderID = "A"
        state.list.dateContext = OrderDateContext(now: Self.now, calendar: Self.calendar)

        // When
        let outcome = OrdersContainerPlan.writeResult(.deleted("A"), state: state)

        // Then
        #expect(outcome.selection == OrdersWriteOutcome.Selection(orderID: nil, shouldNotify: true))
        #expect(outcome.detailPopIDs == ["A"])
    }

    /// 寫入失敗時依原因決定是否要求移除已不存在的詳情，並以一次性通知呈現對應訊息
    ///
    /// - Parameters:
    ///   - failure: 寫入子層回報的失敗原因
    ///   - shouldPopUnavailableDetails: 是否要求移除已不存在的訂單詳情
    ///   - message: 通知內容的本地化訊息
    @Test(arguments: [
        (OrderWriteOperations.Failure.merge, true, "合併訂單儲存失敗，請稍後再試。"),
        (OrderWriteOperations.Failure.delete, false, "訂單刪除失敗，請稍後再試。"),
    ])
    func writeResult_寫入失敗_依原因決定是否移除詳情並顯示通知(
        failure: OrderWriteOperations.Failure,
        shouldPopUnavailableDetails: Bool,
        message: String
    ) {
        // Given
        let state = Self.makeState(orders: [LedgerOrder.fixture(id: "A")])

        // When
        let outcome = OrdersContainerPlan.writeResult(.failed(failure), state: state)

        // Then
        let expected = OrdersPresentationFeature.Destination.State.alert(
            Self.expectedWriteFailureAlert(LocalizedStringKey(message))
        )
        #expect(outcome.shouldPopUnavailableDetails == shouldPopUnavailableDetails)
        #expect(outcome.notice == expected)
    }
}

// MARK: - Private Method

private extension OrdersContainerPlanTests {

    /// 建立寫入失敗的一次性通知，只有「知道了」按鈕且訊息為傳入的本地化鍵
    ///
    /// - Parameter message: 通知顯示的本地化訊息
    /// - Returns: 寫入失敗的 alert
    static func expectedWriteFailureAlert(
        _ message: LocalizedStringKey
    ) -> AlertState<OrdersPresentationFeature.Destination.Alert> {
        AlertState {
            TextState("操作失敗")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("知道了")
            }
        } message: {
            TextState(message)
        }
    }
}
