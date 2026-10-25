//
//  OrdersPresentationFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 提供訂單呈現測試共用的表單、通知與合併目的地
enum OrdersPresentationFeatureTestSupport {}

// MARK: - Internal Method

extension OrdersPresentationFeatureTestSupport {

    /// 建立訂單呈現功能的初始狀態，依需要指定目的地與暫存佇列
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
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState(message)
            }
        )
    }

    /// 建立合併候選表單的目的地，來源訂單為 A 與 B
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
}
