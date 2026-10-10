//
//  OrderListFeatureTests+Dates.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 日期篩選使用清單已記錄的時間，不改讀 reducer 的即時時間
    @Test
    func datePeriodSelected_即時時間與記錄不同_依記錄日期篩選並重選() async {
        // Given
        let april = LedgerOrder.fixture(id: "APRIL", date: TestDependencies.fixedNow)
        let may = LedgerOrder.fixture(id: "MAY", date: Date(timeIntervalSince1970: 1_777_593_600))
        var initial = Self.makeState(orders: [may, april])
        initial.selectedOrderID = "MAY"
        let store = TestStore(initialState: initial) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 1_777_593_600))
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.datePeriodSelected(.thisMonth))) {
            $0.selectedDatePeriod = .thisMonth
            $0.selectedOrderID = "APRIL"
        }

        // Then
        await store.receive(\.delegate.selectionChanged, "APRIL")
        #expect(store.state.filteredOrders.map(\.id) == ["APRIL"])
    }

    /// Root 刷新容器日期後，清單的日期區段立即使用新時間
    @Test
    func refreshDateContext_跨午夜_日期標題由今天改為昨天() {
        // Given
        let order = LedgerOrder.fixture(id: "APRIL", date: TestDependencies.fixedNow)
        var state = OrdersFeature.State(orders: [order])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // When
        state.refreshDateContext(
            now: Date(timeIntervalSince1970: 1_777_593_600),
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        let sections = state.list.dateSections(locale: Locale(identifier: "zh-Hant_TW"))
        #expect(sections.map(\.title) == ["昨天"])
        #expect(sections.flatMap(\.orders).map(\.id) == ["APRIL"])
    }

    /// 刷新時區後，日期區段依清單的注入時區重新分桶
    @Test
    func refreshDateContext_時區不同_同一日訂單合併成一個區段() {
        // Given
        let early = LedgerOrder.fixture(
            id: "EARLY",
            date: Date(timeIntervalSince1970: 1_777_590_000)
        )
        let late = LedgerOrder.fixture(id: "LATE", date: Date(timeIntervalSince1970: 1_777_597_200))
        var calendar = TestDependencies.fixedCalendar
        calendar.timeZone = TimeZone(secondsFromGMT: 28_800) ?? .gmt
        var state = OrdersFeature.State(orders: [early, late])

        // When
        state.refreshDateContext(
            now: Date(timeIntervalSince1970: 1_777_597_200),
            calendar: calendar
        )

        // Then
        let sections = state.list.dateSections(locale: Locale(identifier: "zh-Hant_TW"))
        #expect(sections.map(\.title) == ["今天"])
        #expect(sections.map { $0.orders.map(\.id) } == [["LATE", "EARLY"]])
        #expect(state.list.dateContext?.calendar.timeZone.secondsFromGMT() == 28_800)
    }

    /// 尚未記錄日期時，清單與日期區段均不取用系統時間
    @Test
    func filteredOrders_沒有日期脈絡_回傳空清單與空區段() {
        // Given
        var state = Self.makeState(orders: [LedgerOrder.fixture(id: "A")])
        state.dateContext = nil

        // When
        let orders = state.filteredOrders
        let sections = state.dateSections(locale: Locale(identifier: "zh-Hant_TW"))

        // Then
        #expect(orders.isEmpty)
        #expect(sections.isEmpty)
    }
}
