//
//  MoreFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `MoreFeature` 的單元測試，以 TestStore 驗證更多頁推入各目的地時，建立的狀態與帶入的建構資料
@MainActor
struct MoreFeatureTests {

    /// 驗證匯率頁返回後再進入時建立新狀態，來源幣別與金額回到預設值，且不保留載入中的旗標
    @Test
    func entryTapped_返回後再進入匯率頁_重設輸入與載入狀態() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        var previous = FxFeature.State()
        previous.fromCurrency = .usd
        previous.amount = 12_000
        previous.isLoading = true
        initial.path.append(.fx(previous))
        let store = Self.makeStore(initial: initial)
        await store.send(.path(.popFrom(id: 0))) {
            $0.path.removeAll()
        }

        // When
        await store.send(.view(.entryTapped(.fx))) {
            $0.path.append(.fx(FxFeature.State()))
        }

        // Then
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: 1, case: \.fx]?.fromCurrency == .krw)
        #expect(store.state.path[id: 1, case: \.fx]?.amount == 150_000)
        #expect(store.state.path[id: 1, case: \.fx]?.snapshot == nil)
        #expect(store.state.path[id: 1, case: \.fx]?.isLoading == false)
        await store.finish()
    }

    /// 驗證推入客戶頁時，客戶頁從推入當下就讀到更多頁的同一份訂單投影
    @Test
    func entryTapped_推入客戶頁_讀取同一份訂單投影() async {
        // Given
        let initial = MoreFeature.State(appVersion: "1.7.0")
        let orders = [LedgerOrder.fixture(id: "CUSTOMER-1")]
        initial.$orders.withLock {
            $0 = orders
        }
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.entryTapped(.customers))) {
            $0.path.append(
                .customers(CustomersFeature.State(orders: SharedReader(initial.$orders)))
            )
        }

        // Then
        #expect(store.state.path[id: 0, case: \.customers]?.orders == orders)
        #expect(store.state.path.count == 1)
        await store.finish()
    }

    /// 驗證點選訂單來源列時，推入的主檔頁種類為訂單來源，且路徑只有這一頁
    @Test
    func entryTapped_推入訂單來源頁_建立對應種類() async {
        // Given
        let store = Self.makeStore()

        // When
        await Self.selectLookup(.orderSources, kind: .orderSource, store: store)

        // Then
        #expect(store.state.path[id: 0, case: \.lookupManagement]?.kind == .orderSource)
        await store.finish()
    }

    /// 驗證點選商品類別列時，推入的主檔頁種類為商品類別，且路徑只有這一頁
    @Test
    func entryTapped_推入商品類別頁_建立對應種類() async {
        // Given
        let store = Self.makeStore()

        // When
        await Self.selectLookup(.categories, kind: .category, store: store)

        // Then
        #expect(store.state.path[id: 0, case: \.lookupManagement]?.kind == .category)
        await store.finish()
    }

    /// 驗證點選付款方式列時，推入的主檔頁種類為付款方式，且路徑只有這一頁
    @Test
    func entryTapped_推入付款方式頁_建立對應種類() async {
        // Given
        let store = Self.makeStore()

        // When
        await Self.selectLookup(.paymentMethods, kind: .paymentMethod, store: store)

        // Then
        #expect(store.state.path[id: 0, case: \.lookupManagement]?.kind == .paymentMethod)
        await store.finish()
    }

    /// 驗證點選對帳狀態列時，推入的主檔頁種類為對帳狀態，且路徑只有這一頁
    @Test
    func entryTapped_推入對帳狀態頁_建立對應種類() async {
        // Given
        let store = Self.makeStore()

        // When
        await Self.selectLookup(.reconciliationStatuses, kind: .reconciliationStatus, store: store)

        // Then
        #expect(store.state.path[id: 0, case: \.lookupManagement]?.kind == .reconciliationStatus)
        await store.finish()
    }

    /// 驗證報價頁返回後再進入時，商品價格、運費、各項費率與目標毛利都回到零，匯率來源回到韓圓並重新建立
    @Test
    func entryTapped_返回後再進入報價頁_重設試算輸入與匯率來源() async {
        // Given
        var initial = MoreFeature.State(appVersion: "1.7.0")
        var previous = QuoteFeature.State()
        previous.itemPrice = 9_000
        previous.domesticShipping = 300
        previous.internationalShippingTWD = 100
        previous.cardFeePercent = 3
        previous.paymentFeePercent = 2
        previous.platformFeePercent = 1
        previous.targetMarginPercent = 20
        previous.rateSource.fromCurrency = .usd
        initial.path.append(.quote(previous))
        let store = Self.makeStore(initial: initial)
        await store.send(.path(.popFrom(id: 0))) {
            $0.path.removeAll()
        }

        // When
        await store.send(.view(.entryTapped(.quote))) {
            $0.path.append(.quote(QuoteFeature.State()))
        }

        // Then
        let quote = store.state.path[id: 1, case: \.quote]
        #expect(quote?.itemPrice == 0)
        #expect(quote?.domesticShipping == 0)
        #expect(quote?.internationalShippingTWD == 0)
        #expect(quote?.cardFeePercent == 0)
        #expect(quote?.paymentFeePercent == 0)
        #expect(quote?.platformFeePercent == 0)
        #expect(quote?.targetMarginPercent == 0)
        #expect(quote?.rateSource.fromCurrency == .krw)
        #expect(quote?.rateSource.snapshot == nil)
        await store.finish()
    }

    /// 驗證點選設定列時，先清空既有路徑，再以偏好、版本與辨識類型建立唯一的設定頁
    @Test
    func entryTapped_推入設定頁_帶入偏好版本與辨識類型() async {
        // Given
        let preferences = SettingsSnapshot(
            language: .english,
            defaultCurrency: .usd,
            monthlyProfitGoalTWD: 120_000,
            isAISummaryEnabled: true,
            aiSummaryModel: "deepseek-v3.1:671b",
            isBiometricUnlockEnabled: true
        )
        var initial = MoreFeature.State(appVersion: "1.7.0 (312)")
        initial.preferences = preferences
        initial.biometryType = .faceID
        initial.path.append(.fx(FxFeature.State()))
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.entryTapped(.settings))) {
            $0.path.removeAll()
            $0.path.append(
                .settings(
                    SettingsFeature.State(
                        snapshot: preferences,
                        appVersion: "1.7.0 (312)",
                        biometryType: .faceID
                    )
                )
            )
        }

        // Then
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: 1, case: \.settings]?.language == .english)
        #expect(store.state.path[id: 1, case: \.settings]?.defaultCurrency == .usd)
        #expect(store.state.path[id: 1, case: \.settings]?.monthlyProfitGoalTWD == 120_000)
        #expect(store.state.path[id: 1, case: \.settings]?.snapshot == preferences)
        #expect(store.state.path[id: 1, case: \.settings]?.appVersion == "1.7.0 (312)")
        #expect(store.state.path[id: 1, case: \.settings]?.biometryType == .faceID)
        await store.finish()
    }
}

// MARK: - Private Method

private extension MoreFeatureTests {

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

    /// 送出一個主檔入口並完整斷言推入的種類
    ///
    /// - Parameters:
    ///   - entry: 被點擊的主檔入口
    ///   - kind: 預期建立的主檔種類
    ///   - store: 此條獨立測試的 store
    static func selectLookup(
        _ entry: MoreFeature.Entry,
        kind: LookupKind,
        store: TestStoreOf<MoreFeature>
    ) async {
        await store.send(.view(.entryTapped(entry))) {
            $0.path.append(.lookupManagement(LookupManagementFeature.State(kind: kind)))
        }
    }
}
