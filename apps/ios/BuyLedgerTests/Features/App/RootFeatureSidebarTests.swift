//
//  RootFeatureSidebarTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證 iPad 側邊欄切換分頁時，更多頁導覽路徑的清空與保留
@MainActor
struct RootFeatureSidebarTests {

    /// 驗證 iPad 側邊欄切到其他分頁時，更多頁的導覽路徑先清空，再切換分頁
    @Test
    func sidebarTabSelected_更多路徑非空_清空路徑並切換分頁() async {
        // Given
        var state = RootFeatureTestSupport.makeIsolatedRootState {
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

    /// 驗證 iPad 側邊欄再次選取目前的更多分頁時，更多頁的導覽路徑保持不變
    @Test
    func sidebarTabSelected_選取目前分頁_不清空更多路徑() async {
        // Given
        var state = RootFeatureTestSupport.makeIsolatedRootState {
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
