//
//  OrderListFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 訂單清單的日期記錄與交給容器的請求
@MainActor
struct OrderListFeatureTests {

    /// 已載入或載入中仍先更新日期，再請容器統一判斷是否載入
    ///
    /// - Parameters:
    ///   - hasLoaded: 是否已載入
    ///   - isLoading: 是否正在載入
    @Test(arguments: [false, true], [false, true])
    func task_各種載入旗標_記錄日期並委派載入(hasLoaded: Bool, isLoading: Bool) async {
        // Given
        var initial = Self.makeState()
        initial.dateContext = nil
        initial.$hasLoaded = SharedReader(value: hasLoaded)
        initial.$isLoading = SharedReader(value: isLoading)
        let store = TestStore(initialState: initial) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.loadRequested)
        #expect(store.state.hasLoaded == hasLoaded)
        #expect(store.state.isLoading == isLoading)
    }

    /// 重試先以新時間取代舊日期記錄，再交給容器載入
    @Test
    func retryTapped_已有日期記錄_更新日期並委派載入() async {
        // Given
        var initial = Self.makeState()
        initial.dateContext = OrderDateContext(
            now: Date(timeIntervalSince1970: 0),
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.loadRequested)
        #expect(store.state.dateContext?.now == TestDependencies.fixedNow)
    }

    /// 點新增只送出新增請求，表單由容器呈現
    @Test
    func newOrderTapped_點擊新增_委派新增請求() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.newOrderTapped))

        // Then
        await store.receive(\.delegate.requested, .create)
    }

    /// 點編輯只送出編輯請求，並帶上訂單識別值
    @Test
    func editOrderTapped_點擊編輯_委派編輯請求() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.editOrderTapped("A")))

        // Then
        await store.receive(\.delegate.requested, .edit("A"))
    }

    /// 點合併只送出合併請求，並帶上訂單識別值
    @Test
    func mergeOrderTapped_點擊合併_委派合併請求() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.mergeOrderTapped("A")))

        // Then
        await store.receive(\.delegate.requested, .merge("A"))
    }

    /// 點刪除只送出刪除請求，並帶上訂單識別值
    @Test
    func deleteOrderTapped_點擊刪除_委派刪除請求() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.deleteOrderTapped("A")))

        // Then
        await store.receive(\.delegate.requested, .delete("A"))
    }

    /// 點訂單只送出顯示詳情請求，並帶上訂單識別值
    @Test
    func orderTapped_點擊訂單_委派顯示詳情請求() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.orderTapped("A")))

        // Then
        await store.receive(\.delegate.requested, .showDetail("A"))
    }

    /// 點 AI 摘要只送出摘要請求，呈現交給容器
    @Test
    func aiSummaryTapped_點擊摘要_委派摘要請求() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.aiSummaryTapped))

        // Then
        await store.receive(\.delegate.requested, .aiSummary)
    }

    /// 選取右欄訂單時回報新的識別值
    @Test
    func orderSelected_選取訂單_更新選取並通知容器() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.orderSelected("B"))) {
            $0.selectedOrderID = "B"
        }

        // Then
        await store.receive(\.delegate.selectionChanged, "B")
    }
}

// MARK: - Internal Method

extension OrderListFeatureTests {

    /// 建立固定日期與唯讀訂單的清單，不讀取系統時間
    ///
    /// - Parameter orders: 初始訂單
    /// - Returns: 清單測試的初始狀態
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static func makeState(orders: [LedgerOrder] = []) -> OrderListFeature.State {
        let sharedOrders = Shared<[LedgerOrder]>(value: [])
        sharedOrders.withLock {
            $0 = orders
        }
        var state = OrderListFeature.State(orders: SharedReader(sharedOrders))
        state.dateContext = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        return state
    }
}
