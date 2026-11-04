//
//  MoreFeatureEntrySelectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/29.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `MoreFeature` 的入口選取單元測試，以 TestStore 與狀態推導驗證同工具保留、不同工具替換、返回清空與目前入口
@MainActor
struct MoreFeatureEntrySelectionTests {

    /// 驗證已開啟匯率頁時選取報價頁，根目的地替換為報價頁且不殘留匯率頁
    @Test
    func entrySelected_已開啟其他工具_替換根目的地() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        initial.path.append(.fx(FxFeature.State()))
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.entrySelected(.quote))) {
            $0.path.removeAll()
            $0.path.append(.quote(QuoteFeature.State()))
        }

        // Then
        #expect(store.state.path.count == 1)
    }

    /// 驗證匯率頁已輸入金額時再次選取匯率頁，保留既有輸入與堆疊元素識別值而不重建
    @Test
    func entrySelected_匯率頁已開啟_保留既有狀態不重建() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        var fx = FxFeature.State()
        fx.amount = 12_000
        initial.path.append(.fx(fx))
        let pathIDs = initial.path.ids
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.entrySelected(.fx)))

        // Then
        #expect(store.state.path.ids == pathIDs)
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: 0, case: \.fx]?.amount == 12_000)
    }

    /// 驗證設定頁已修改月目標時再次選取設定，保留既有設定頁、其欄位與堆疊元素識別值而不重建
    @Test
    func entrySelected_設定頁已開啟_保留既有設定頁不重建() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        var settings = SettingsFeature.State(
            snapshot: .default,
            appVersion: "1.7.0",
            biometryType: .unavailable
        )
        settings.monthlyProfitGoalTWD = 12_345
        initial.path.append(.settings(settings))
        let pathIDs = initial.path.ids
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.entrySelected(.settings)))

        // Then
        #expect(store.state.path.ids == pathIDs)
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: 0, case: \.settings]?.monthlyProfitGoalTWD == 12_345)
    }

    /// 驗證收合後以原生返回離開匯率頁時，`nil` 選取清空根目的地並回到入口清單
    @Test
    func entrySelected_傳入nil_清空根目的地() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        initial.path.append(.fx(FxFeature.State()))
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.entrySelected(nil))) {
            $0.path.removeAll()
        }

        // Then
        #expect(store.state.path.isEmpty)
    }

    /// 驗證已開啟付款方式主檔時選取商品類別主檔，根目的地替換為類別主檔
    @Test
    func entrySelected_已開啟其他主檔_替換為新種類() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        await LookupCatalog.withIsolatedStorage {
            initial.path.append(
                .lookupManagement(LookupManagementFeature.State(kind: .paymentMethod))
            )
        }
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.entrySelected(.lookup(.category)))) {
            $0.path.removeAll()
            $0.path.append(.lookupManagement(LookupManagementFeature.State(kind: .category)))
        }

        // Then
        #expect(store.state.path.count == 1)
    }

    /// 驗證路徑推入設定頁時，目前入口推導為設定
    @Test
    func currentEntry_路徑推入設定頁_回傳設定() {
        // Given
        var state = MoreFeature.State(appVersion: "1.7.0")
        state.path.append(
            .settings(
                SettingsFeature.State(
                    snapshot: .default,
                    appVersion: "1.7.0",
                    biometryType: .unavailable
                )
            )
        )

        // When
        let entry = state.currentEntry

        // Then
        #expect(entry == .settings)
    }

    /// 驗證路徑推入付款方式主檔時，目前入口推導為付款方式入口
    @Test
    func currentEntry_路徑推入主檔頁_回傳對應入口() async {
        // Given
        var state = MoreFeature.State(appVersion: "1.7.0")
        await LookupCatalog.withIsolatedStorage {
            state.path.append(
                .lookupManagement(LookupManagementFeature.State(kind: .paymentMethod))
            )
        }

        // When
        let entry = state.currentEntry

        // Then
        #expect(entry == .lookup(.paymentMethod))
    }

    /// 驗證初始更多頁沒有目前工具，入口清單不會自動開啟任何工具
    @Test
    func currentEntry_未選取_路徑為空且無目前入口() {
        // Given
        let state = MoreFeature.State(appVersion: "1.7.0")

        // When
        let entry = state.currentEntry

        // Then
        #expect(state.path.isEmpty)
        #expect(entry == nil)
    }
}

// MARK: - Private Method

private extension MoreFeatureEntrySelectionTests {

    /// 建立隔離主檔目錄的更多頁 `TestStore`
    ///
    /// - Parameter initial: 要驗證的初始狀態
    /// - Returns: 不會污染其他測試主檔的 store
    static func makeStore(
        initial: MoreFeature.State = MoreFeature.State(appVersion: "1.7.0")
    ) -> TestStoreOf<MoreFeature> {
        TestStore(initialState: initial) {
            MoreFeature()
        } withDependencies: {
            $0.defaultInMemoryStorage = InMemoryStorage()
        }
    }
}
