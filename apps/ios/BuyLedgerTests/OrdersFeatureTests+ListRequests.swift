//
//  OrdersFeatureTests+ListRequests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 分頁重新出現時先記錄日期，再交給根功能確認主檔目錄與訂單載入
    @Test
    func list_已載入分頁再次出現_先記錄日期再經容器請求載入() async {
        // Given
        let initial = OrdersFeature.State()
        initial.load.$hasLoaded.withLock {
            $0 = true
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.list(.view(.task))) {
            $0.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.list.delegate.loadRequested)
        await store.receive(\.delegate.loadRequested)
        #expect(store.state.list.hasLoaded)
        #expect(store.state.list.isLoading == false)
    }

    /// 點擊清單中的訂單後，畫面推入該訂單的詳情
    @Test
    func list_點擊訂單列_經請求計畫推入詳情() async {
        // Given
        let order = LedgerOrder.fixture(id: "A")
        let store = TestStore(initialState: OrdersFeature.State(orders: [order])) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.list(.view(.orderTapped("A"))))

        // Then
        await store.receive(\.list.delegate.requested, .showDetail("A")) {
            $0.detail.path[id: 0] = .detail(
                OrderDetailFeature.State(orderID: "A", orders: SharedReader($0.$orders))
            )
        }
        #expect(store.state.detail.path.count == 1)
        #expect(store.state.detail.path[id: 0]?.detail?.orderID == "A")
    }

    /// 開始合併時沿用清單已記下的時間與時區，即使目前的時間與時區不同也不覆寫
    ///
    /// - Throws: 無法建立測試時區時由 `#require` 丟出
    @Test
    func list_開始合併時已有日期脈絡_候選沿用清單時間與時區() async throws {
        // Given
        let primary = LedgerOrder.fixture(id: "A")
        let secondary = LedgerOrder.fixture(id: "B")
        var calendar = TestDependencies.fixedCalendar
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 28_800))
        let dateContext = OrderDateContext(
            now: Date(timeIntervalSince1970: 1_777_480_200),
            calendar: calendar
        )
        var initial = OrdersFeature.State(orders: [primary, secondary])
        initial.list.dateContext = dateContext
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(0))
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.list(.view(.mergeOrderTapped("A"))))

        // Then
        await store.receive(\.list.delegate.requested, .merge("A")) {
            $0.presentation.destination = .merge(
                OrderMergeFeature.State(
                    primary: primary,
                    orders: [primary, secondary],
                    dateContext: dateContext
                )
            )
        }
        #expect(
            store.state.presentation.destination?.merge?.dateContext.now
                == Date(timeIntervalSince1970: 1_777_480_200)
        )
        #expect(
            store.state.presentation.destination?.merge?.dateContext.calendar.timeZone
                .secondsFromGMT() == 28_800
        )
        #expect(store.state.presentation.destination?.merge?.candidates.map(\.id) == ["B"])
        #expect(store.state.list.dateContext == dateContext)
    }

    /// 清單還沒記下時間就開始合併時，合併候選改用目前的時間與時區
    ///
    /// - Throws: 無法建立測試時區時由 `#require` 丟出
    @Test
    func list_清單尚無日期脈絡_候選使用注入時間與時區() async throws {
        // Given
        let primary = LedgerOrder.fixture(id: "A")
        let secondary = LedgerOrder.fixture(id: "B")
        var calendar = TestDependencies.fixedCalendar
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: -25_200))
        let initial = OrdersFeature.State(orders: [primary, secondary])
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(0))
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = calendar
        }

        // When
        await store.send(.list(.delegate(.requested(.merge("A"))))) {
            $0.presentation.destination = .merge(
                OrderMergeFeature.State(
                    primary: primary,
                    orders: [primary, secondary],
                    dateContext: OrderDateContext(
                        now: TestDependencies.fixedNow,
                        calendar: calendar
                    )
                )
            )
        }

        // Then
        #expect(
            store.state.presentation.destination?.merge?.dateContext.now
                == TestDependencies.fixedNow
        )
        #expect(
            store.state.presentation.destination?.merge?.dateContext.calendar.timeZone
                .secondsFromGMT() == -25_200
        )
        #expect(store.state.presentation.destination?.merge?.candidates.map(\.id) == ["B"])
        #expect(store.state.list.dateContext == nil)
    }
}
