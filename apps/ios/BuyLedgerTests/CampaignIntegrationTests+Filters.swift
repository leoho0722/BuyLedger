//
//  CampaignIntegrationTests+Filters.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension CampaignIntegrationTests {

    /// 指定團名篩選只留下對應訂單，不包含其他團與未歸團訂單
    @Test
    func campaignFilterSelected_指定開團名稱_只顯示該團訂單() async {
        // Given
        var state = OrdersFeature.State()
        state.orders = [
            Self.makeOrder(id: "O1", campaign: "團A"),
            Self.makeOrder(id: "O2", campaign: "團B"),
            Self.makeOrder(id: "O3", campaign: ""),
        ]
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.campaignFilterSelected("團A")) {
            $0.selectedCampaign = "團A"
            $0.selectedOrderID = "O1"
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == ["O1"])
    }

    /// 從進行中改篩已結束時，篩選依開團副本的狀態選出不同訂單，未歸團訂單不納入
    ///
    /// - Throws: 初始篩選未選出進行中訂單時由 `try #require` 丟出
    @Test
    func campaignStatusFilterSelected_變更開團狀態篩選_依開團副本選出對應訂單() async throws(any Error) {
        // Given
        var state = OrdersFeature.State()
        state.orders = [
            Self.makeOrder(id: "O1", campaign: "團A"),
            Self.makeOrder(id: "O2", campaign: "團B"),
            Self.makeOrder(id: "O3", campaign: ""),
        ]
        state.campaigns = [
            Campaign.fixture(
                id: "A",
                name: "團A",
                openDate: TestDependencies.fixedNow,
                status: .ongoing
            ),
            Campaign.fixture(
                id: "B",
                name: "團B",
                openDate: TestDependencies.fixedNow,
                status: .closed
            ),
        ]
        state.selectedCampaignStatus = .ongoing
        state.selectedOrderID = "O1"
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let ongoingIDs = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        ).map(\.id)

        try #require(ongoingIDs == ["O1"])

        // When
        await store.send(.campaignStatusFilterSelected(.closed)) {
            $0.selectedCampaignStatus = .closed
            $0.selectedOrderID = "O2"
        }

        // Then
        let closedIDs = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        ).map(\.id)
        #expect(closedIDs == ["O2"])
    }
}
