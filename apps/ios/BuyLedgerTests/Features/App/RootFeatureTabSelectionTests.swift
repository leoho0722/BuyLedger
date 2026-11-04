//
//  RootFeatureTabSelectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 `TestStore` 驗證切換根分頁時更多頁導覽狀態的保留
@MainActor
struct RootFeatureTabSelectionTests {

    /// 驗證更多頁停在設定頁時切到訂單分頁，`tabSelected` 保留導覽路徑與設定頁狀態
    @Test
    func tabSelected_設定頁非空時切到訂單_保留更多路徑與設定狀態() async {
        // Given
        var state = RootFeatureTestSupport.makeIsolatedRootState {
            var initial = RootFeature.State()
            var settings = SettingsFeature.State(appVersion: "1.7.0")
            settings.monthlyProfitGoalTWD = 123_456
            initial.more.path.append(.settings(settings))
            return initial
        }
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.view(.tabSelected(.orders))) {
            $0.selectedTab = .orders
        }

        // Then
        #expect(store.state.more.path.count == 1)
        #expect(store.state.more.path[id: 0, case: \.settings]?.monthlyProfitGoalTWD == 123_456)
    }

    /// 驗證更多頁停在主檔管理頁時切到訂單分頁，`tabSelected` 保留導覽路徑與載入狀態
    @Test
    func tabSelected_主檔頁非空時切到訂單_保留更多路徑與載入狀態() async {
        // Given
        var state = RootFeatureTestSupport.makeIsolatedRootState {
            var initial = RootFeature.State()
            var lookup = LookupManagementFeature.State(kind: .category)
            lookup.hasLoaded = true
            initial.more.path.append(.lookupManagement(lookup))
            return initial
        }
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.view(.tabSelected(.orders))) {
            $0.selectedTab = .orders
        }

        // Then
        #expect(store.state.more.path.count == 1)
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.kind == .category)
        #expect(store.state.more.path[id: 0, case: \.lookupManagement]?.hasLoaded == true)
    }

    /// 驗證再次選取目前的更多分頁時，`tabSelected` 不改變任何狀態
    @Test
    func tabSelected_選取目前分頁_狀態不變() async {
        // Given
        var state = RootFeatureTestSupport.makeIsolatedRootState(lookupKind: .category)
        state.selectedTab = .more

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.view(.tabSelected(.more)))

        // Then
        #expect(store.state.more.path.count == 1)
        #expect(store.state.selectedTab == .more)
    }
}
