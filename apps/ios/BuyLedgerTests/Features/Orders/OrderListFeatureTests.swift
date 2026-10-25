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

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證日期脈絡的記錄與點擊操作後送給 `OrdersFeature` 的請求
@MainActor
struct OrderListFeatureTests {

    /// 驗證任務開始時，不論是否已載入或正在載入，都先記錄日期脈絡，再送出載入請求，由 `OrdersFeature` 決定是否真正載入
    ///
    /// - Parameters:
    ///   - hasLoaded: 是否已載入
    ///   - isLoading: 是否正在載入
    @Test(arguments: [false, true], [false, true])
    func task_各種載入旗標_記錄日期並委派載入(hasLoaded: Bool, isLoading: Bool) async {
        // Given
        var initial = OrderListFeatureTestSupport.makeState()
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

    /// 驗證按下重試時，舊的日期記錄先換成目前時間，再送出載入請求
    @Test
    func retryTapped_已有日期記錄_更新日期並委派載入() async {
        // Given
        var initial = OrderListFeatureTestSupport.makeState()
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

    /// 驗證點擊新增時只送出新增請求，不自行開啟表單
    @Test
    func newOrderTapped_點擊新增_委派新增請求() async {
        // Given
        let store = TestStore(initialState: OrderListFeatureTestSupport.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.newOrderTapped))

        // Then
        await store.receive(\.delegate.requested, .create)
    }

    /// 驗證點擊編輯時只送出帶有訂單 A 識別值的編輯請求，不改變清單狀態
    @Test
    func editOrderTapped_點擊編輯_委派編輯請求() async {
        // Given
        let store = TestStore(initialState: OrderListFeatureTestSupport.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.editOrderTapped("A")))

        // Then
        await store.receive(\.delegate.requested, .edit("A"))
    }

    /// 驗證點擊合併時只送出帶有訂單 A 識別值的合併請求，不改變清單狀態
    @Test
    func mergeOrderTapped_點擊合併_委派合併請求() async {
        // Given
        let store = TestStore(initialState: OrderListFeatureTestSupport.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.mergeOrderTapped("A")))

        // Then
        await store.receive(\.delegate.requested, .merge("A"))
    }

    /// 驗證點擊刪除時只送出帶有訂單 A 識別值的刪除請求，不改變清單狀態
    @Test
    func deleteOrderTapped_點擊刪除_委派刪除請求() async {
        // Given
        let store = TestStore(initialState: OrderListFeatureTestSupport.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.deleteOrderTapped("A")))

        // Then
        await store.receive(\.delegate.requested, .delete("A"))
    }

    /// 驗證點擊訂單時只送出帶有訂單 A 識別值的顯示詳情請求，不改變清單狀態
    @Test
    func orderTapped_點擊訂單_委派顯示詳情請求() async {
        // Given
        let store = TestStore(initialState: OrderListFeatureTestSupport.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.orderTapped("A")))

        // Then
        await store.receive(\.delegate.requested, .showDetail("A"))
    }

    /// 驗證點擊 AI 摘要時只送出摘要請求，不自行呈現摘要
    @Test
    func aiSummaryTapped_點擊摘要_委派摘要請求() async {
        // Given
        let store = TestStore(initialState: OrderListFeatureTestSupport.makeState()) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.aiSummaryTapped))

        // Then
        await store.receive(\.delegate.requested, .aiSummary)
    }

    /// 驗證選取訂單 B 時，清單更新選取的識別值，並送出 `selectionChanged` 通知
    @Test
    func orderSelected_選取訂單_更新選取並通知容器() async {
        // Given
        let store = TestStore(initialState: OrderListFeatureTestSupport.makeState()) {
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
