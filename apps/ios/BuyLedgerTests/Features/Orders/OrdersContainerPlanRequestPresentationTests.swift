//
//  OrdersContainerPlanRequestPresentationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersContainerPlan` 的單元測試，涵蓋請求產生的編輯、合併、刪除與摘要目的地
struct OrdersContainerPlanRequestPresentationTests {

    /// 驗證識別值與日期脈絡齊備時，編輯既有訂單會呈現帶入原訂單內容的編輯表單，且不是合併情境
    ///
    /// - Throws: 呈現的目的地不是訂單編輯表單時由 `#require` 丟出
    @Test
    func fulfill_編輯既有訂單齊備識別值與日期脈絡_呈現編輯表單() throws {
        // Given
        let state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A", chargedAmount: 1_500),
        ])
        let context = OrderDateContext(
            now: OrdersContainerPlanTestSupport.now,
            calendar: OrdersContainerPlanTestSupport.calendar
        )

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .edit("A"),
            state: state,
            context: context,
            formID: UUID(1)
        )

        // Then
        let destination = try #require(Self.presentedDestination(outcome))
        let edit = try #require(OrdersContainerPlanTestSupport.editState(of: destination))
        #expect(edit.id == UUID(1))
        #expect(edit.original?.id == "A")
        #expect(edit.draft.customerName == "測試客戶")
        #expect(edit.draft.chargedAmount == 1_500)
        #expect(edit.draft.currency == .twd)
        #expect(!edit.isMergeContext)
        #expect(edit.calendar == OrdersContainerPlanTestSupport.calendar)
    }

    /// 驗證識別值與日期脈絡齊備時，新增請求呈現空白表單，幣別採用狀態的 `defaultCurrency`
    ///
    /// - Throws: 呈現的目的地不是訂單編輯表單時由 `#require` 丟出
    @Test
    func fulfill_新增訂單齊備識別值與日期脈絡_呈現空白表單() throws {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [])
        state.defaultCurrency = .usd
        let context = OrderDateContext(
            now: OrdersContainerPlanTestSupport.now,
            calendar: OrdersContainerPlanTestSupport.calendar
        )

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .create,
            state: state,
            context: context,
            formID: UUID(2)
        )

        // Then
        let destination = try #require(Self.presentedDestination(outcome))
        let edit = try #require(OrdersContainerPlanTestSupport.editState(of: destination))
        #expect(edit.id == UUID(2))
        #expect(edit.original == nil)
        #expect(edit.draft.date == OrdersContainerPlanTestSupport.now)
        #expect(edit.draft.currency == .usd)
        #expect(edit.draft.status == .quoting)
    }

    /// 驗證刪除請求呈現確認 alert，標題、刪除與取消按鈕及說明文字都符合預期，刪除按鈕帶著該訂單的識別值
    ///
    /// - Throws: 呈現的目的地不是 alert 時由 `#require` 丟出
    @Test
    func fulfill_刪除訂單_呈現刪除確認alert() throws {
        // Given
        let state = OrdersContainerPlanTestSupport.makeState(orders: [LedgerOrder.fixture(id: "A")])

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .delete("A"),
            state: state,
            context: nil,
            formID: nil
        )

        // Then
        let destination = try #require(Self.presentedDestination(outcome))
        let alert = Self.expectedDeletionConfirmation(orderID: "A", customerName: "測試客戶")
        #expect(destination == .alert(alert))
    }

    /// 驗證可合併的訂單發起合併時，清單已記錄的日期脈絡優先於傳入的值，候選清單只有 B
    ///
    /// - Throws: 呈現的目的地不是合併候選表單時由 `#require` 丟出
    @Test
    func fulfill_合併可合併訂單清單已有日期脈絡_沿用清單的日期脈絡() throws {
        // Given
        var state = Self.makeMergeState()
        state.list.dateContext = OrderDateContext(
            now: OrdersContainerPlanTestSupport.now,
            calendar: OrdersContainerPlanTestSupport.calendar
        )
        let passedNow = Date(timeIntervalSince1970: 1_790_000_000)
        let passed = OrderDateContext(
            now: passedNow,
            calendar: OrdersContainerPlanTestSupport.calendar
        )

        // When
        let outcome = withDependencies {
            $0.uuid = .constant(UUID(3))
        } operation: {
            OrdersContainerPlan.fulfill(
                .merge("A"),
                state: state,
                context: passed,
                formID: nil
            )
        }

        // Then
        let destination = try #require(Self.presentedDestination(outcome))
        let merge = try #require(Self.mergeState(of: destination))
        #expect(merge.id == UUID(3))
        #expect(merge.primary.id == "A")
        #expect(merge.candidates.map(\.id) == ["B"])
        #expect(merge.dateContext.now == OrdersContainerPlanTestSupport.now)
    }

    /// 驗證清單沒有日期脈絡時，可合併的訂單發起合併改用傳入的日期脈絡，候選表單的時間也以它為準
    ///
    /// - Throws: 呈現的目的地不是合併候選表單時由 `#require` 丟出
    @Test
    func fulfill_合併可合併訂單清單無日期脈絡_改用傳入的日期脈絡() throws {
        // Given
        let state = Self.makeMergeState()
        let passedNow = Date(timeIntervalSince1970: 1_790_000_000)
        let passed = OrderDateContext(
            now: passedNow,
            calendar: OrdersContainerPlanTestSupport.calendar
        )

        // When
        let outcome = withDependencies {
            $0.uuid = .constant(UUID(3))
        } operation: {
            OrdersContainerPlan.fulfill(
                .merge("A"),
                state: state,
                context: passed,
                formID: nil
            )
        }

        // Then
        let destination = try #require(Self.presentedDestination(outcome))
        let merge = try #require(Self.mergeState(of: destination))
        #expect(merge.primary.id == "A")
        #expect(merge.dateContext.now == passedNow)
    }

    /// 驗證 AI 摘要未啟用時，呈現帶關閉與前往設定兩個按鈕的提示 alert，不產生摘要內容
    ///
    /// - Throws: 呈現的目的地不是 alert 時由 `#require` 丟出
    @Test
    func fulfill_AI摘要未啟用_呈現未啟用的提示() throws {
        // Given
        var state = OrdersContainerPlanTestSupport.makeState(orders: [])
        state.aiSummarySettings = OrderAISummarySettings(isEnabled: false, model: "test-model")

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .aiSummary,
            state: state,
            context: nil,
            formID: nil
        )

        // Then
        let destination = try #require(Self.presentedDestination(outcome))
        #expect(destination == .alert(Self.aiDisabledAlert()))
    }

    /// 驗證 AI 摘要已啟用時，呈現帶模型與提示文字的摘要狀態，提示內容涵蓋清單目前的所有類別
    ///
    /// - Throws: 呈現的目的地不是 AI 摘要時由 `#require` 丟出
    @Test
    func fulfill_AI摘要已啟用_呈現帶模型與提示文字的摘要() throws {
        // Given
        let item = LedgerOrderItem(
            id: UUID(9),
            name: "測試品項",
            quantity: 2,
            unitPrice: 100
        )
        var state = OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A", items: [item], categories: ["測試類別"]),
        ])
        state.aiSummarySettings = OrderAISummarySettings(isEnabled: true, model: "test-model")
        state.list.dateContext = OrderDateContext(
            now: OrdersContainerPlanTestSupport.now,
            calendar: OrdersContainerPlanTestSupport.calendar
        )

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .aiSummary,
            state: state,
            context: nil,
            formID: nil
        )

        // Then
        let destination = try #require(Self.presentedDestination(outcome))
        let summary = try #require(Self.aiSummaryState(of: destination))
        #expect(summary.model == "test-model")
        #expect(summary.prompt.contains("(涵蓋目前列表所有類別)"))
        #expect(summary.prompt.contains("- [測試類別] 測試品項 x2 @ 100 TWD"))
    }
}

// MARK: - Private Method

private extension OrdersContainerPlanRequestPresentationTests {

    /// 取出 `.present` 結果中的目的地，其他結果為 `nil`
    ///
    /// - Parameter outcome: `fulfill` 回傳的請求結果
    /// - Returns: 要呈現的目的地
    static func presentedDestination(
        _ outcome: OrdersRequestOutcome
    ) -> OrdersPresentationFeature.Destination.State? {
        guard case .present(let destination) = outcome else {
            return nil
        }
        return destination
    }

    /// 建立刪除訂單的確認 alert，確認按鈕帶著要刪除的訂單識別值
    ///
    /// - Parameters:
    ///   - orderID: 要刪除的訂單識別值
    ///   - customerName: 訂單的客戶名稱
    /// - Returns: 刪除確認 alert
    static func expectedDeletionConfirmation(
        orderID: LedgerOrder.ID,
        customerName: String
    ) -> AlertState<OrdersPresentationFeature.Destination.Alert> {
        AlertState {
            TextState("orders.detail.label.deleteOrder")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(orderID)) {
                TextState("common.action.button.delete")
            }
            ButtonState(role: .cancel) {
                TextState("common.action.cancel")
            }
        } message: {
            TextState(
                LocalizedStringResource(
                    "orders.detail.message.deleteUndoneNotice",
                    defaultValue: "\(customerName)"
                )
            )
        }
    }

    /// 建立可合併的訂單 A、同客戶同幣別的候選 B，以及不符資格的其他客戶與已合併訂單
    ///
    /// - Returns: `OrdersFeature` 狀態，A 的候選清單只有 B
    static func makeMergeState() -> OrdersFeature.State {
        OrdersContainerPlanTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
            LedgerOrder.fixture(
                id: "C",
                customer: LedgerCustomer(name: "其他客戶", initials: "OT", tier: .regular)
            ),
            LedgerOrder.fixture(id: "M", status: .merged),
        ])
    }

    /// 取出目的地中的合併候選狀態，其他種類的目的地為 `nil`
    ///
    /// - Parameter destination: 要查詢的呈現目的地
    /// - Returns: 合併候選表單的狀態
    static func mergeState(
        of destination: OrdersPresentationFeature.Destination.State
    ) -> OrderMergeFeature.State? {
        guard case .merge(let merge) = destination else {
            return nil
        }
        return merge
    }

    /// 建立 AI 商品明細總結未啟用的提示，提供關閉與前往設定兩個按鈕
    ///
    /// - Returns: 未啟用提示的 alert
    static func aiDisabledAlert() -> AlertState<OrdersPresentationFeature.Destination.Alert> {
        AlertState {
            TextState("orders.general.label.aiItemSummary")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("common.action.label.close")
            }
            ButtonState(action: .goToAISettings) {
                TextState("orders.general.label.openSettings2")
            }
        } message: {
            TextState("orders.general.message.enableAiItem")
        }
    }

    /// 取出目的地中的 AI 摘要狀態，其他種類的目的地為 `nil`
    ///
    /// - Parameter destination: 要查詢的呈現目的地
    /// - Returns: AI 摘要的狀態
    static func aiSummaryState(
        of destination: OrdersPresentationFeature.Destination.State
    ) -> AISummaryFeature.State? {
        guard case .aiSummary(let summary) = destination else {
            return nil
        }
        return summary
    }
}
