//
//  FxFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證匯率工具的狀態更新與計算
@MainActor
struct FxFeatureTests {

    // MARK: - Properties

    /// 換算結果為 JPY 5、KRW 8 的固定匯率快照
    ///
    /// - Note: 標 `nonisolated` 讓依賴覆寫的 `@Sendable` closure 能讀取
    nonisolated private static let fixedSnapshot = FxRateSnapshot(
        date: Date(timeIntervalSince1970: 123),
        base: .twd,
        rates: [
            .twd: 1,
            .jpy: Decimal(sign: .plus, exponent: -1, significand: 2),
            .krw: Decimal(sign: .plus, exponent: -3, significand: 125),
        ]
    )

    // MARK: - Tests

    /// 驗證預設狀態使用韓元與十五萬元
    @Test
    func init_預設兌換狀態_以韓元與十五萬元開始() {
        // Given

        // When
        let state = FxFeature.State()

        // Then
        #expect(state.fromCurrency == .krw)
        #expect(state.amount == 150_000)
    }

    /// 驗證預設狀態尚未有快照與換算結果
    @Test
    func init_預設兌換狀態_沒有快照與匯率() {
        // Given

        // When
        let state = FxFeature.State()

        // Then
        #expect(state.snapshot == nil)
        #expect(state.rate == nil)
        #expect(state.convertedTWD == nil)
    }

    /// 驗證切換幣別後依自訂快照重算匯率
    @Test
    func binding_切換來源幣別_依快照重算匯率() async {
        // Given
        let store = TestStore(initialState: FxFeature.State(snapshot: Self.fixedSnapshot)) {
            FxFeature()
        }

        // When
        await store.send(\.binding.fromCurrency, .jpy) {
            $0.fromCurrency = .jpy
        }

        // Then
        #expect(store.state.rate == 5)
        #expect(store.state.convertedTWD == 750_000)
    }

    /// 驗證快速金額按鈕會取代目前金額
    @Test
    func quickAmountTapped_選取快捷金額_取代目前金額() async {
        // Given
        let store = TestStore(initialState: FxFeature.State()) {
            FxFeature()
        }

        // When
        await store.send(.view(.quickAmountTapped(50_000))) {
            $0.amount = 50_000
        }

        // Then
        #expect(store.state.amount == 50_000)
    }

    /// 驗證金額繫結會更新 TWD 換算結果
    @Test
    func binding_金額改變_更新新台幣換算金額() async {
        // Given
        let store = TestStore(initialState: FxFeature.State(snapshot: Self.fixedSnapshot)) {
            FxFeature()
        }

        // When
        await store.send(\.binding.amount, 100_000) {
            $0.amount = 100_000
        }

        // Then
        #expect(store.state.rate == 8)
        #expect(store.state.convertedTWD == 800_000)
    }

    /// 驗證新台幣在沒有快照時仍以一比一計算
    @Test
    func displayRate_查詢新台幣且沒有快照_回傳一() {
        // Given
        let state = FxFeature.State()

        // When
        let rate = state.displayRate(for: .twd)

        // Then
        #expect(rate == 1)
    }

    /// 驗證匯率列表會排除新台幣
    @Test
    func ratesListCurrencies_可用幣別包含新台幣_排除新台幣() {
        // Given
        let state = FxFeature.State(availableCurrencies: [.twd, .krw, .jpy])

        // When
        let currencies = state.ratesListCurrencies

        // Then
        #expect(currencies == [.krw, .jpy])
    }

    /// 驗證點擊幣別列會呈現選擇目的地
    @Test
    func currencyPickerTapped_點選幣別按鈕_呈現幣別選擇畫面() async {
        // Given
        let store = TestStore(initialState: FxFeature.State()) {
            FxFeature()
        }

        // When
        await store.send(.view(.currencyPickerTapped)) {
            $0.destination = .currencyPicker
        }

        // Then
        #expect(store.state.destination == .currencyPicker)
    }

    /// 驗證選定幣別後更新來源幣別並關閉目的地
    @Test
    func currencySelected_選取可用幣別_更新幣別並關閉選擇畫面() async {
        // Given
        let store = TestStore(initialState: FxFeature.State(destination: .currencyPicker)) {
            FxFeature()
        }

        // When
        await store.send(.view(.currencySelected("JPY"))) {
            $0.fromCurrency = .jpy
            $0.destination = nil
        }

        // Then
        #expect(store.state.fromCurrency == .jpy)
        #expect(store.state.destination == nil)
    }

    /// 驗證幣別清單失敗時保留原有清單
    @Test
    func currencyCodesResponse_載入幣別失敗_保留目前幣別清單() async {
        // Given
        let initialState = FxFeature.State(availableCurrencies: [.jpy, .krw, .twd])
        let store = TestStore(initialState: initialState) {
            FxFeature()
        }

        // When
        await store.send(.currencyCodesResponse(.failure(.api(.invalidKey))))

        // Then
        #expect(store.state.availableCurrencies == [.jpy, .krw, .twd])
    }

    /// 驗證重試會重新載入匯率與幣別清單
    @Test
    func retryTapped_重新載入_再次取得匯率與幣別() async {
        // Given
        let initialState = FxFeature.State(errorMessage: "網路連線異常；無法顯示即時匯率，請稍後再試。")
        let store = TestStore(initialState: initialState) {
            FxFeature()
        } withDependencies: {
            $0.exchangeRateService.fetchLatest = { _ in
                Self.fixedSnapshot
            }
            $0.currencyMetadataService.fetchCodes = {
                [.twd, .jpy, .krw]
            }
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        // Then
        await store.receive(\.currencyCodesResponse.success) {
            $0.availableCurrencies = [.jpy, .krw, .twd]
        }
        await store.receive(\.ratesResponse.success) {
            $0.isLoading = false
            $0.snapshot = Self.fixedSnapshot
        }
    }
}
