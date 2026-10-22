//
//  RootFeatureTests+Sidebar.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// iPad 側邊欄切換分頁前清空「更多」路徑
    @Test
    func sidebarTabSelected_更多路徑非空_清空路徑並切換分頁() async {
        // Given
        var state = Self.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.more.path.append(
                .lookupManagement(LookupManagementFeature.State(kind: .category))
            )
            return initial
        }
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.view(.sidebarTabSelected(.orders))) {
            $0.more.path.removeAll()
            $0.selectedTab = .orders
        }

        // Then
        #expect(store.state.more.path.isEmpty)
        #expect(store.state.selectedTab == .orders)
    }

    /// iPad 側邊欄選取目前分頁時不清空「更多」路徑
    @Test
    func sidebarTabSelected_選取目前分頁_不清空更多路徑() async {
        // Given
        var state = Self.makeIsolatedRootState {
            var initial = RootFeature.State()
            initial.more.path.append(
                .lookupManagement(LookupManagementFeature.State(kind: .category))
            )
            return initial
        }
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.view(.sidebarTabSelected(.more)))

        // Then
        #expect(store.state.more.path.count == 1)
        #expect(store.state.selectedTab == .more)
    }
}
