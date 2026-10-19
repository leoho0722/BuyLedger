//
//  RootFeatureTests+DetailNavigation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 分析頁點選類別時，已顯示的訂單 A 換成該類別的訂單 B，清單與右欄同步
    ///
    /// - Throws: 初始詳情不是訂單 A 時由 `#require` 丟出
    @Test
    func insights_詳情已有訂單時開類別深連結_右欄改成新訂單() async throws {
        // Given
        var initial = Self.makeIsolatedRootState()
        initial.orders.$orders.withLock {
            $0 = [
                LedgerOrder.fixture(id: "A", categories: ["服飾"]),
                LedgerOrder.fixture(id: "B", categories: ["美妝"]),
            ]
        }
        initial.orders.list.selectedOrderID = "A"
        initial.orders.detail.regularDetail = OrderDetailFeature.State(
            orderID: "A",
            orders: SharedReader(initial.orders.$orders)
        )
        try #require(initial.orders.detail.regularDetail?.order?.id == "A")
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("美妝")))) {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.selectedCategories = ["美妝"]
            $0.orders.list.selectedOrderID = "B"
            $0.orders.detail.regularDetail = OrderDetailFeature.State(
                orderID: "B",
                orders: SharedReader($0.orders.$orders)
            )
        }

        // Then
        #expect(store.state.orders.list.selectedOrderID == "B")
        #expect(store.state.orders.detail.regularDetail?.orderID == "B")
        #expect(store.state.orders.detail.regularDetail?.order?.id == "B")
    }
}
