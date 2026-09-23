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

    /// 供匯率計算測試使用的固定快照
    nonisolated private static let fixedSnapshot = FxRateSnapshot(
        date: Date(timeIntervalSince1970: 123),
        base: .twd,
        rates: [
            .twd: 1,
            .jpy: Decimal(string: "0.2")!,
            .krw: Decimal(string: "0.125")!
        ]
    )

    // MARK: - Tests

    /// 驗證預設狀態使用韓圓與十五萬元
    @Test func defaultStateUsesKrwAt150K() {
        // Given

        // When
        let state = FxFeature.State()

        // Then
        #expect(state.fromCurrency == .krw)
        #expect(state.amount == 150_000)
    }

    /// 驗證預設狀態尚未有快照與換算結果
    @Test func defaultStateHasNoSnapshotAndNilRate() {
        // Given

        // When
        let state = FxFeature.State()

        // Then
        #expect(state.snapshot == nil)
        #expect(state.rate == nil)
        #expect(state.convertedTWD == nil)
    }

    /// 驗證切換幣別後依自訂快照重算匯率
    @Test func switchingCurrencyRecomputesRateFromSnapshot() async {
        // Given
        let store = TestStore(
            initialState: FxFeature.State(snapshot: Self.fixedSnapshot)
        ) {
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
    @Test func quickAmountTappedReplacesAmount() async {
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
    @Test func bindingAmountUpdatesConvertedTWD() async {
        // Given
        let store = TestStore(
            initialState: FxFeature.State(snapshot: Self.fixedSnapshot)
        ) {
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
    @Test func displayRateForTwdAlwaysReturnsOneEvenWithoutSnapshot() {
        // Given
        let state = FxFeature.State()

        // When
        let rate = state.displayRate(for: .twd)

        // Then
        #expect(rate == 1)
    }

    /// 驗證匯率列表會排除新台幣
    @Test func ratesListCurrenciesExcludesTwd() {
        // Given
        let state = FxFeature.State(availableCurrencies: [.twd, .krw, .jpy])

        // When
        let currencies = state.ratesListCurrencies

        // Then
        #expect(currencies == [.krw, .jpy])
    }

    /// 驗證點擊幣別列會呈現選擇目的地
    @Test func currencyPickerTappedPresentsDestination() async {
        // Given
        let store = TestStore(initialState: FxFeature.State()) {
            FxFeature()
        }

        // When
        await store.send(.view(.currencyPickerTapped)) {
            $0.destination = .currencyPicker
        }

        // Then
        #expect(store.state.destination != nil)
    }

    /// 驗證選定幣別後更新來源幣別並關閉目的地
    @Test func currencySelectedUpdatesCurrencyAndDismissesDestination() async {
        // Given
        let store = TestStore(
            initialState: FxFeature.State(destination: .currencyPicker)
        ) {
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
    @Test func currencyCodesFailureKeepsExistingCurrencies() async {
        // Given
        let existingCurrencies: [CurrencyCode] = [.jpy, .krw, .twd]
        let store = TestStore(
            initialState: FxFeature.State(availableCurrencies: existingCurrencies)
        ) {
            FxFeature()
        }

        // When
        await store.send(
            .currencyCodesResponse(.failure(.api(.invalidKey)))
        )

        // Then
        #expect(store.state.availableCurrencies == existingCurrencies)
    }

    /// 驗證重試會重新載入匯率與幣別清單
    @Test func retryTappedReloadsRatesAndCurrencies() async {
        // Given
        let store = TestStore(
            initialState: FxFeature.State(
                errorMessage: "網路連線異常；無法顯示即時匯率，請稍後再試。"
            )
        ) {
            FxFeature()
        } withDependencies: {
            $0[ExchangeRateClient.self].fetchLatest = { _ in
                Self.fixedSnapshot
            }
            $0[CurrencyMetadataRepository.self].fetchCodes = {
                [.twd, .jpy, .krw]
            }
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.currencyCodesResponse.success) {
            $0.availableCurrencies = [.jpy, .krw, .twd]
        }
        await store.receive(\.ratesResponse.success) {
            $0.isLoading = false
            $0.snapshot = Self.fixedSnapshot
        }

        // Then
        #expect(store.state.isLoading == false)
        #expect(store.state.snapshot == Self.fixedSnapshot)
        #expect(store.state.availableCurrencies == [.jpy, .krw, .twd])
    }
}
