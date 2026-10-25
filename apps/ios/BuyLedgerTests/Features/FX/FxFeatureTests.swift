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

/// `FxFeature` 的單元測試，以 TestStore 逐步驗證狀態更新，並直接檢查匯率與換算計算
struct FxFeatureTests {

    // MARK: - Properties

    /// 1 JPY 兌 5 TWD、1 KRW 兌 8 TWD 的固定匯率快照
    private static let fixedSnapshot = FxRateSnapshot(
        date: Date(timeIntervalSince1970: 123),
        base: .twd,
        rates: [
            .twd: 1,
            .jpy: Decimal(sign: .plus, exponent: -1, significand: 2),
            .krw: Decimal(sign: .plus, exponent: -3, significand: 125),
        ]
    )

    /// 驗證預設狀態的來源幣別為韓元 (`.krw`)、金額為 150,000
    @Test
    func init_預設兌換狀態_以韓元與十五萬元開始() {
        // Given

        // When
        let state = FxFeature.State()

        // Then
        #expect(state.fromCurrency == .krw)
        #expect(state.amount == 150_000)
    }

    /// 驗證預設狀態沒有快照，`rate` 與 `convertedTWD` 皆為 `nil`
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

    /// 驗證切換來源幣別為 `.jpy` 後，依固定快照重算 `rate`，金額 150,000 換算為 750,000
    @Test
    @MainActor
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

    /// 驗證點選快捷金額 50,000 時，`amount` 取代為 50,000，不與原金額累加
    @Test
    @MainActor
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

    /// 驗證金額改為 100,000 時，`rate` 為 8，`convertedTWD` 更新為 800,000
    @Test
    @MainActor
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

    /// 驗證沒有快照時，`displayRate(for:)` 查詢新台幣仍回傳 1
    @Test
    func displayRate_查詢新台幣且沒有快照_回傳一() {
        // Given
        let state = FxFeature.State()

        // When
        let rate = state.displayRate(for: .twd)

        // Then
        #expect(rate == 1)
    }

    /// 驗證可用幣別包含新台幣時，`ratesListCurrencies` 排除新台幣，其餘依清單順序保留
    @Test
    func ratesListCurrencies_可用幣別包含新台幣_排除新台幣() {
        // Given
        let state = FxFeature.State(availableCurrencies: [.twd, .krw, .jpy])

        // When
        let currencies = state.ratesListCurrencies

        // Then
        #expect(currencies == [.krw, .jpy])
    }

    /// 驗證點選幣別按鈕時，`destination` 設為幣別選擇畫面
    @Test
    @MainActor
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

    /// 驗證選定 JPY 後，`fromCurrency` 更新為 `.jpy`，`destination` 清為 `nil` 以關閉選擇畫面
    @Test
    @MainActor
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

    /// 驗證載入幣別清單失敗時，`availableCurrencies` 保留原有的 JPY、KRW、TWD 清單
    @Test
    @MainActor
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

    /// 驗證畫面出現時匯率請求遇到傳輸層錯誤，`isLoading` 結束、`errorMessage` 顯示網路連線異常，幣別清單仍照常載入
    @Test
    @MainActor
    func task_匯率請求傳輸層失敗_結束載入並顯示網路連線異常訊息() async {
        // Given
        let failingFetchLatest: ExchangeRateService.FetchLatest = { _ throws(APIError) in
            throw .transport(
                underlying: TestDependencies.makeUnderlyingError(message: "network unavailable")
            )
        }
        let store = TestStore(initialState: FxFeature.State()) {
            FxFeature()
        } withDependencies: {
            $0.exchangeRateService.fetchLatest = failingFetchLatest
            $0.currencyMetadataService.fetchCodes = {
                [.twd, .jpy, .krw]
            }
        }

        // When
        await store.send(.view(.task)) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.currencyCodesResponse.success) {
            $0.availableCurrencies = [.jpy, .krw, .twd]
        }
        await store.receive(\.ratesResponse) {
            $0.isLoading = false
            $0.errorMessage = "fx.rates.message.networkErrorOccurred"
        }
    }

    /// 驗證重試時清除 `errorMessage` 並重新載入幣別清單與匯率，匯率成功後寫入 `snapshot`
    @Test
    @MainActor
    func retryTapped_重新載入_再次取得匯率與幣別() async {
        // Given
        let initialState = FxFeature.State(errorMessage: "fx.rates.message.networkErrorOccurred")
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
