//
//  RootFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Testing
@testable import BuyLedger

@MainActor
struct RootFeatureTests {
    
    // MARK: - Tests
    
    @Test func smartGroupSelectedJumpsToOrdersAndAppliesStatus() async {
        var state = RootFeature.State()
        state.selectedTab = .dashboard
        state.orders.orders = LedgerOrder.sampleOrders
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }
        
        await store.send(.smartGroupSelected(.shipping)) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.shipping)
            $0.orders.selectedOrderID = "BL-2604-018"
        }
    }
    
    @Test func smartGroupSelectedResetsDatePeriodAndPreviousStatus() async {
        var state = RootFeature.State()
        state.selectedTab = .dashboard
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.selectedStatus = .status(.delivered)
        state.orders.selectedDatePeriod = .thisMonth
        state.orders.selectedOrderID = "BL-2604-016"
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }
        
        await store.send(.smartGroupSelected(.shipping)) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.shipping)
            $0.orders.selectedDatePeriod = .all
            $0.orders.selectedOrderID = "BL-2604-018"
        }
    }
    
    @Test func smartGroupSelectionFlipsCorrespondingStatusChipPredicate() async {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }
        
        await store.send(.smartGroupSelected(.purchased)) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.purchased)
            $0.orders.selectedOrderID = "BL-2604-017"
        }
        
        // 確認對應 chip 的「isSelected」判定（與 view 端 `store.selectedStatus == filter` 一致）會翻成 true，
        // 其餘狀態 chip 維持 false，避免未來 reducer 變更時 UI 同步行為悄悄走樣。
        let purchasedFilter = OrderStatusFilter.status(.purchased)
        #expect(store.state.orders.selectedStatus == purchasedFilter)
        
        let otherFilters: [OrderStatusFilter] = OrderStatusFilter.orderBrowsingCases
            .filter { $0 != purchasedFilter }
        for filter in otherFilters {
            #expect(store.state.orders.selectedStatus != filter)
        }
    }
}
