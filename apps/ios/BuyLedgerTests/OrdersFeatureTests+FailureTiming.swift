//
//  OrdersFeatureTests+FailureTiming.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 三種表單開啟中收到寫入失敗時，表單保持開著並暫存通知
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
        await store.send(.presentation(.noticeRequested(Self.failureNotice("第一則失敗")))) {
            $0.presentation.queue.pendingNotice = Self.failureNotice("第一則失敗")
        }

        // Then
        #expect(store.state.presentation.destination == destination)
        #expect(store.state.presentation.queue.pendingNotice == Self.failureNotice("第一則失敗"))
    }

    /// 三種表單被關閉時清空目的地並標記關閉中，暫存通知留到關閉回呼才顯示
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
        initial.presentation.queue.pendingNotice = Self.failureNotice("第一則失敗")
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
        #expect(store.state.presentation.queue.pendingNotice == Self.failureNotice("第一則失敗"))
    }

    /// 通知已取出並關閉後，表單重複收到關閉通知時不會再次出現
    @Test
    func formSheetDismissed_通知已取出後再次回呼_不重複呈現() async {
        // Given
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.formSheetDismissed))

        // Then
        #expect(store.state.presentation.destination == nil)
        #expect(store.state.presentation.queue == OrdersPresentationQueue())
    }

    /// 表單已清空但關閉動畫尚未完成時再收到通知，新通知取代先前暫存的通知
    @Test
    func presentation_關閉中已有暫存通知_只保留最新一則() async {
        // Given
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = Self.failureNotice("第一則失敗")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.presentation(.noticeRequested(Self.failureNotice("第二則失敗")))) {
            $0.presentation.queue.pendingNotice = Self.failureNotice("第二則失敗")
        }

        // Then
        #expect(store.state.presentation.queue.pendingNotice == Self.failureNotice("第二則失敗"))
    }

    /// 關閉動畫完成時取出暫存的最新通知並呈現，暫存隨之清空
    @Test
    func formSheetDismissed_關閉中有暫存通知_呈現最新一則() async {
        // Given
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = Self.failureNotice("第二則失敗")
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
            $0.presentation.destination = Self.failureNotice("第二則失敗")
        }

        // Then
        #expect(store.state.presentation.destination == Self.failureNotice("第二則失敗"))
        #expect(store.state.presentation.queue == OrdersPresentationQueue())
    }
}

// MARK: - Nested Types

extension OrdersFeatureTests {

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

// MARK: - Internal Method

extension OrdersFeatureTests {

    /// 建立只有「知道了」按鈕的失敗通知，供比對預期值
    ///
    /// - Parameter message: 預期通知訊息
    /// - Returns: `.alert` case 的目的地狀態，可直接指派給訂單分頁的目的地或暫存通知
    static func failureNotice(
        _ message: LocalizedStringKey
    ) -> OrdersPresentationFeature.Destination.State {
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

    /// 以唯讀常數目錄建立已有「美妝」類別且開著編輯表單的訂單分頁狀態
    ///
    /// - Returns: `OrdersFeature.State` 值，可直接作為 `TestStore` 的初始狀態
    static func makeOptionState() -> OrdersFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            var state = OrdersFeature.State()
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.$lookupCatalog = SharedReader(value: LookupCatalog(categories: ["美妝"]))
            state.list.$lookupCatalog = state.$lookupCatalog
            state.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: OrderEditOptions(
                        categories: ["美妝"],
                        calendar: TestDependencies.fixedCalendar
                    ),
                    currentDate: TestDependencies.fixedNow
                )
            )
            state.presentation.destination?.modify(\.edit) {
                $0.draft.categories = ["美妝"]
            }
            return state
        }
    }
}

// MARK: - Private Method

private extension OrdersFeatureTests {

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
