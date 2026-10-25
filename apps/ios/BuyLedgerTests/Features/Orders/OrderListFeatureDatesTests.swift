//
//  OrderListFeatureDatesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，涵蓋日期篩選、日期脈絡刷新與日期區段分組
struct OrderListFeatureDatesTests {

    /// 驗證選擇本月時，清單依已記錄的日期脈絡判定本月，不採用注入的即時時間，只留下 APRIL 並重選它
    @Test
    @MainActor
    func datePeriodSelected_即時時間與記錄不同_依記錄日期篩選並重選() async {
        // Given
        let april = LedgerOrder.fixture(id: "APRIL", date: TestDependencies.fixedNow)
        let may = LedgerOrder.fixture(id: "MAY", date: Date(timeIntervalSince1970: 1_777_593_600))
        var initial = OrderListFeatureTestSupport.makeState(orders: [may, april])
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

    /// 驗證刷新日期脈絡跨過午夜後，同一筆 APRIL 訂單的日期區段標題由今天變成昨天
    @Test
    func refreshDateContext_跨午夜_日期標題由今天改為昨天() {
        // Given
        let order = LedgerOrder.fixture(id: "APRIL", date: TestDependencies.fixedNow)
        var state = OrdersFeature.State(orders: [order])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let initialSnapshot = state.list.listSnapshot()
        let initialSections = OrdersListQuery.dateSections(
            orders: initialSnapshot.orders,
            context: state.list.dateContext,
            locale: Locale(identifier: "zh-Hant_TW")
        )

        // When
        state.refreshDateContext(
            now: Date(timeIntervalSince1970: 1_777_593_600),
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        let snapshot = state.list.listSnapshot()
        let sections = OrdersListQuery.dateSections(
            orders: snapshot.orders,
            context: state.list.dateContext,
            locale: Locale(identifier: "zh-Hant_TW")
        )
        #expect(initialSections.map(\.title) == ["今天"])
        #expect(sections.map(\.title) == ["昨天"])
        #expect(sections.flatMap(\.orders).map(\.id) == ["APRIL"])
    }

    /// 驗證刷新時區為 UTC+8 後，相隔兩小時的兩筆訂單落在同一天，合併為一個今天的區段，且依時間由新到舊排列
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
        let snapshot = state.list.listSnapshot()
        let sections = OrdersListQuery.dateSections(
            orders: snapshot.orders,
            context: state.list.dateContext,
            locale: Locale(identifier: "zh-Hant_TW")
        )
        #expect(sections.map(\.title) == ["今天"])
        #expect(sections.map { $0.orders.map(\.id) } == [["LATE", "EARLY"]])
        #expect(state.list.dateContext?.calendar.timeZone.secondsFromGMT() == 28_800)
    }

    /// 驗證尚未記錄日期脈絡時，清單快照與日期區段都是空結果，即使訂單本身有日期
    @Test
    func listSnapshot_沒有日期脈絡_回傳空清單與空區段() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A", date: TestDependencies.fixedNow),
        ])
        state.dateContext = nil

        // When
        let snapshot = state.listSnapshot()
        let sections = OrdersListQuery.dateSections(
            orders: snapshot.orders,
            context: state.dateContext,
            locale: Locale(identifier: "zh-Hant_TW")
        )

        // Then
        #expect(snapshot.orders == [])
        #expect(sections == [])
    }

    /// 驗證已記錄日期脈絡但類別篩選沒有命中任何訂單時，日期區段為空
    @Test
    func dateSections_篩選無結果_回傳空區段() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A", date: TestDependencies.fixedNow, categories: ["美妝"]),
        ])
        state.selectedCategories = ["食品"]

        // When
        let snapshot = state.listSnapshot()
        let sections = OrdersListQuery.dateSections(
            orders: snapshot.orders,
            context: state.dateContext,
            locale: Locale(identifier: "zh-Hant_TW")
        )

        // Then
        #expect(sections == [])
    }
}
