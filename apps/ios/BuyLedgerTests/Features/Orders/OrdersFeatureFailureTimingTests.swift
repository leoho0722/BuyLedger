//
//  OrdersFeatureFailureTimingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證表單開關轉場中的失敗通知暫存與呈現
@MainActor
struct OrdersFeatureFailureTimingTests {

    /// 驗證三種表單開啟中收到寫入失敗的通知時，表單保持開著，通知暫存在 `pendingNotice` 等待關閉
    ///
    /// - Parameter sheet: 目前開啟的表單種類
    @Test(arguments: FormSheet.allCases)
    func presentation_三種表單開啟中收到通知_暫存通知並保留表單(sheet: FormSheet) async {
        // Given
        let destination = Self.makeTimingDestination(sheet)
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.destination = destination
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .presentation(.noticeRequested(OrdersFeatureTestSupport.failureNotice("第一則失敗")))
        ) {
            $0.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice("第一則失敗")
        }

        // Then
        #expect(store.state.presentation.destination == destination)
        #expect(
            store.state.presentation.queue.pendingNotice
                == OrdersFeatureTestSupport.failureNotice("第一則失敗")
        )
    }

    /// 驗證三種表單被關閉時，目的地清空並標記為關閉中，暫存通知仍保留
    ///
    /// - Parameter sheet: 要關閉的表單種類
    @Test(arguments: FormSheet.allCases)
    func presentation_三種表單關閉_標記關閉中並保留暫存通知(sheet: FormSheet) async {
        // Given
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.destination = Self.makeTimingDestination(sheet)
        initial.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice("第一則失敗")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.presentation(.destination(.dismiss))) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }

        // Then
        #expect(store.state.presentation.destination == nil)
        #expect(
            store.state.presentation.queue.pendingNotice
                == OrdersFeatureTestSupport.failureNotice("第一則失敗")
        )
    }

    /// 驗證通知已取出並呈現後，再收到關閉回呼時，呈現中的通知不變，暫存維持為空
    @Test
    func formSheetDismissed_通知已取出後再次回呼_不重複呈現() async {
        // Given
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.destination = OrdersFeatureTestSupport.failureNotice("第一則失敗")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.formSheetDismissed))

        // Then
        #expect(
            store.state.presentation.destination == OrdersFeatureTestSupport.failureNotice("第一則失敗")
        )
        #expect(store.state.presentation.queue.isFormClosing == false)
        #expect(store.state.presentation.queue.pendingNotice == nil)
    }

    /// 驗證表單關閉中再收到通知時，新通知取代先前暫存的通知，只保留最新一則
    @Test
    func presentation_關閉中已有暫存通知_只保留最新一則() async {
        // Given
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice("第一則失敗")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .presentation(.noticeRequested(OrdersFeatureTestSupport.failureNotice("第二則失敗")))
        ) {
            $0.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice("第二則失敗")
        }

        // Then
        #expect(
            store.state.presentation.queue.pendingNotice
                == OrdersFeatureTestSupport.failureNotice("第二則失敗")
        )
    }

    /// 驗證關閉動畫完成時，取出暫存的最新通知並呈現，暫存隨之清空
    @Test
    func formSheetDismissed_關閉中有暫存通知_呈現最新一則() async {
        // Given
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice("第二則失敗")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = OrdersFeatureTestSupport.failureNotice("第二則失敗")
        }

        // Then
        #expect(
            store.state.presentation.destination == OrdersFeatureTestSupport.failureNotice("第二則失敗")
        )
        #expect(store.state.presentation.queue.isFormClosing == false)
        #expect(store.state.presentation.queue.isAwaitingMergeConfirmation == false)
        #expect(store.state.presentation.queue.pendingNotice == nil)
        #expect(store.state.presentation.queue.pendingMergeConfirmation == nil)
    }
}

// MARK: - Nested Types

extension OrdersFeatureFailureTimingTests {

    /// 會讓失敗通知等表單關好才顯示的表單種類
    enum FormSheet: CaseIterable, Sendable {

        /// 訂單編輯表單
        case edit

        /// 合併候選表單
        case merge

        /// AI 摘要表單
        case aiSummary
    }
}

// MARK: - Private Method

private extension OrdersFeatureFailureTimingTests {

    /// 建立指定種類的表單，識別碼與時間都固定，測試不依賴系統時間
    ///
    /// - Parameter sheet: 要建立的表單種類
    /// - Returns: 可直接指派給訂單分頁狀態的表單
    static func makeTimingDestination(
        _ sheet: FormSheet
    ) -> OrdersPresentationFeature.Destination.State {
        switch sheet {
        case .edit:
            return .edit(
                OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
            )

        case .merge:
            return withDependencies {
                $0.uuid = .constant(UUID(0))
            } operation: {
                .merge(
                    OrderMergeFeature.State(
                        primary: LedgerOrder.fixture(id: "A"),
                        orders: [],
                        dateContext: OrderDateContext(
                            now: TestDependencies.fixedNow,
                            calendar: TestDependencies.fixedCalendar
                        )
                    )
                )
            }

        case .aiSummary:
            return .aiSummary(AISummaryFeature.State(prompt: "測試摘要", model: "gpt-oss:120b"))
        }
    }
}
