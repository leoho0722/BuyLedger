//
//  OrdersPresentationFeatureTests+Fixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

// MARK: - Internal Method

extension OrdersPresentationFeatureTests {

    /// 建立呈現子層的初始狀態，依需要指定目的地與暫存佇列
    ///
    /// - Parameters:
    ///   - destination: 初始目的地，`nil` 代表沒有表單或提示
    ///   - queue: 初始暫存佇列
    /// - Returns: 指定目的地與佇列的呈現狀態
    static func makeState(
        destination: OrdersPresentationFeature.Destination.State? = nil,
        queue: OrdersPresentationQueue = OrdersPresentationQueue()
    ) -> OrdersPresentationFeature.State {
        var state = OrdersPresentationFeature.State()
        state.destination = destination
        state.queue = queue
        return state
    }

    /// 建立新增或編輯訂單的表單狀態，表單識別值預設為 `UUID(0)`
    ///
    /// - Parameters:
    ///   - id: 表單識別值
    ///   - original: 要編輯的訂單，`nil` 代表新訂單
    /// - Returns: 固定日期的表單狀態
    static func editState(
        id: UUID = UUID(0),
        original: LedgerOrder? = nil
    ) -> OrderEditFeature.State {
        OrderEditFeature.State(original: original, id: id, currentDate: TestDependencies.fixedNow)
    }

    /// 建立寫入失敗的一次性提示，只有「知道了」按鈕
    ///
    /// - Parameter message: 提示的說明文字
    /// - Returns: 帶有指定說明的提示目的地
    static func failureNotice(_ message: String) -> OrdersPresentationFeature.Destination.State {
        .alert(
            AlertState<OrdersPresentationFeature.Destination.Alert> {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState(message)
            }
        )
    }

    /// 建立刪除訂單的確認提示，刪除按鈕帶入訂單識別值 `A`
    ///
    /// - Returns: 帶有確認刪除動作的提示目的地
    static func deleteAlert() -> OrdersPresentationFeature.Destination.State {
        .alert(
            AlertState<OrdersPresentationFeature.Destination.Alert> {
                TextState("刪除訂單")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete("A")) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除後無法復原")
            }
        )
    }

    /// 建立 AI 商品明細摘要未啟用的提示，前往開啟按鈕帶入設定動作
    ///
    /// - Returns: 帶有前往設定動作的提示目的地
    static func aiSettingsAlert() -> OrdersPresentationFeature.Destination.State {
        .alert(
            AlertState<OrdersPresentationFeature.Destination.Alert> {
                TextState("AI 商品明細總結")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("關閉")
                }
                ButtonState(action: .goToAISettings) {
                    TextState("前往開啟")
                }
            } message: {
                TextState("此功能需要先開啟")
            }
        )
    }

    /// 建立合併候選表單的目的地，來源訂單為 `A` 與 `B`
    ///
    /// - Returns: 帶有合併候選狀態的目的地
    static func mergeDestination() -> OrdersPresentationFeature.Destination.State {
        let primary = LedgerOrder.fixture(id: "A")
        let secondary = LedgerOrder.fixture(id: "B")
        return withDependencies {
            $0.uuid = .constant(UUID(0))
        } operation: {
            .merge(
                OrderMergeFeature.State(
                    primary: primary,
                    orders: [primary, secondary],
                    dateContext: OrderDateContext(
                        now: TestDependencies.fixedNow,
                        calendar: TestDependencies.fixedCalendar
                    )
                )
            )
        }
    }

    /// 建立合併候選完成時的草稿，來源為 `A` 與 `B`，由 `OrderMerge` 依固定時間產生
    ///
    /// - Returns: 合併後的草稿值，作為測試的輸入
    static func mergeDraft() -> OrderMerge.Draft {
        OrderMerge.makeDraft(
            primary: LedgerOrder.fixture(id: "A"),
            secondary: LedgerOrder.fixture(id: "B"),
            now: TestDependencies.fixedNow,
            isCardless: { _ in false }
        )
    }
}
