//
//  QuoteFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證報價試算流程
struct QuoteFeatureTests {

    // MARK: - Properties

    /// 供計算測試使用的固定匯率快照：1 韓元折 8 元、1 日圓折 5 元
    private static let fixedSnapshot = FxRateSnapshot(
        date: Date(timeIntervalSince1970: 123),
        base: .twd,
        rates: [
            .twd: 1,
            .jpy: Decimal(sign: .plus, exponent: -1, significand: 2),
            .krw: Decimal(sign: .plus, exponent: -3, significand: 125),
        ]
    )

    // MARK: - Tests

    /// 未帶參數建立時，來源幣別為韓元，所有金額與費率輸入為零
    @Test
    func init_未帶參數_來源幣別為韓元且輸入皆為零() {
        // Given

        // When
        let state = QuoteFeature.State()

        // Then
        #expect(state.rateSource.fromCurrency == .krw)
        #expect(state.itemPrice == 0)
        #expect(state.domesticShipping == 0)
        #expect(state.internationalShippingTWD == 0)
        #expect(state.cardFeePercent == 0)
        #expect(state.paymentFeePercent == 0)
        #expect(state.platformFeePercent == 0)
        #expect(state.targetMarginPercent == 0)
    }

    /// 使用韓元快照與刷卡手續費時，成本依匯率折算後加總
    @Test
    func costTWD_含來源幣別匯率與刷卡費_加總總成本() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw, snapshot: Self.fixedSnapshot),
            itemPrice: 100_000,
            cardFeePercent: 2
        )

        // When
        let itemTWD = state.itemTWD
        let cardFeeTWD = state.cardFeeTWD
        let costTWD = state.costTWD

        // Then
        #expect(itemTWD == 800_000)
        #expect(cardFeeTWD == 16_000)
        #expect(costTWD == 816_000)
    }

    /// 沒有匯率快照時，只有國際運費會保留在新台幣成本
    @Test
    func costTWD_沒有匯率快照_只保留國際運費() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw),
            itemPrice: 100_000,
            domesticShipping: 5_000,
            internationalShippingTWD: 180,
            cardFeePercent: 2.5
        )

        // When
        let itemTWD = state.itemTWD
        let domesticTWD = state.domesticTWD
        let cardFeeTWD = state.cardFeeTWD
        let costTWD = state.costTWD

        // Then
        #expect(itemTWD == 0)
        #expect(domesticTWD == 0)
        #expect(cardFeeTWD == 0)
        #expect(costTWD == 180)
    }

    /// 成本除以目標毛利後，建議售價無條件進位到十元
    @Test
    func suggestedTWD_成本除以目標毛利_無條件進位到十元() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 100,
            targetMarginPercent: 25
        )

        // When
        let suggestedTWD = state.suggestedTWD
        let estimatedProfitTWD = state.estimatedProfitTWD

        // Then
        // 成本 100 / (1 - 0.25) = 133.33，無條件進位到 140
        #expect(suggestedTWD == 140)
        #expect(estimatedProfitTWD == 40)
    }

    /// 來源幣別從韓元切成新台幣後，商品金額改以 1:1 折算新台幣
    @Test
    @MainActor
    func currencySelected_切換來源幣別_重算商品新台幣金額() async {
        // Given
        let store = TestStore(
            initialState: QuoteFeature.State(
                rateSource: QuoteRateFeature.State(snapshot: Self.fixedSnapshot),
                itemPrice: 150_000
            )
        ) {
            QuoteFeature()
        }

        // When
        await store.send(.view(.currencySelected("TWD")))

        // Then
        await store.receive(\.rateSource.currencySelected) {
            $0.rateSource.fromCurrency = .twd
        }
        #expect(store.state.itemTWD == 150_000)
    }

    /// 目標毛利改變時，建議售價會依新比例更新
    @Test
    @MainActor
    func binding_目標毛利改變_更新建議售價() async {
        // Given
        let store = TestStore(
            initialState: QuoteFeature.State(
                rateSource: QuoteRateFeature.State(fromCurrency: .twd),
                itemPrice: 1_000,
                targetMarginPercent: 10
            )
        ) {
            QuoteFeature()
        }

        // When
        await store.send(\.binding.targetMarginPercent, 50) {
            $0.targetMarginPercent = 50
        }

        // Then
        #expect(store.state.suggestedTWD == 2_000)
    }

    /// 商品金額輸入負值時會夾限為零
    @Test
    @MainActor
    func binding_輸入負數金額_夾限為零() async {
        // Given
        let store = TestStore(
            initialState: QuoteFeature.State(
                rateSource: QuoteRateFeature.State(fromCurrency: .twd),
                itemPrice: 500,
                targetMarginPercent: 30
            )
        ) {
            QuoteFeature()
        }

        // When
        await store.send(\.binding.itemPrice, -100) {
            $0.itemPrice = 0
        }

        // Then
        #expect(store.state.itemPrice == 0)
    }

    /// 幣別選擇畫面未開啟時，點選按鈕會開啟畫面
    @Test
    @MainActor
    func currencyPickerTapped_選擇畫面未開啟_開啟幣別選擇畫面() async {
        // Given
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        }

        // When
        await store.send(.view(.currencyPickerTapped))

        // Then
        await store.receive(\.rateSource.pickerTapped) {
            $0.rateSource.destination = .currencyPicker
        }
    }

    /// 幣別選擇畫面開啟中，選取新幣別後更新來源並關閉畫面
    @Test
    @MainActor
    func currencySelected_選擇畫面開啟中_更新幣別並關閉選擇畫面() async {
        // Given
        let store = TestStore(
            initialState: QuoteFeature.State(
                rateSource: QuoteRateFeature.State(destination: .currencyPicker)
            )
        ) {
            QuoteFeature()
        }

        // When
        await store.send(.view(.currencySelected("TWD")))

        // Then
        await store.receive(\.rateSource.currencySelected) {
            $0.rateSource.fromCurrency = .twd
            $0.rateSource.destination = nil
        }
    }

    /// 目標毛利 0%、30%、50% 時，建議售價符合公式且毛利率達標
    ///
    /// - Parameters:
    ///   - targetMarginPercent: 目標毛利 (%)
    ///   - expectedSuggestedTWD: 預期的建議售價 (TWD)
    /// - Throws: 算不出預估毛利率時由 `#require` 丟出
    @Test(arguments: [(0, 1_000), (30, 1_430), (50, 2_000)])
    func suggestedTWD_毛利公式範例_售價符合公式且毛利率達標(
        targetMarginPercent: Int,
        expectedSuggestedTWD: Int
    ) throws {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_000,
            targetMarginPercent: Decimal(targetMarginPercent)
        )

        // When
        let suggestedTWD = state.suggestedTWD
        let estimatedMarginPercent = state.estimatedMarginPercent

        // Then
        let marginPercent = try #require(estimatedMarginPercent)
        #expect(suggestedTWD == Decimal(expectedSuggestedTWD))
        #expect(marginPercent >= Decimal(targetMarginPercent))
        #expect(marginPercent < Decimal(targetMarginPercent + 1))
    }

    /// 目標毛利低於 100% 才提供建議售價
    ///
    /// - Parameters:
    ///   - targetMarginPercent: 要設定的目標毛利 (%)
    ///   - hasSuggestedPrice: 預期是否提供建議售價
    @Test(arguments: [(99, true), (100, false), (150, false)])
    @MainActor
    func binding_目標毛利在百分之百前後_依門檻決定是否提供建議售價(
        targetMarginPercent: Int,
        hasSuggestedPrice: Bool
    ) async {
        // Given
        let store = TestStore(
            initialState: QuoteFeature.State(
                rateSource: QuoteRateFeature.State(fromCurrency: .twd),
                itemPrice: 1_000,
                targetMarginPercent: 50
            )
        ) {
            QuoteFeature()
        }

        // When
        await store.send(\.binding.targetMarginPercent, Decimal(targetMarginPercent)) {
            $0.targetMarginPercent = Decimal(targetMarginPercent)
        }

        // Then
        #expect((store.state.suggestedTWD != nil) == hasSuggestedPrice)
    }

    /// 十進位金額相加不會產生二進位浮點誤差
    ///
    /// - Throws: 字面值無法轉成 `Decimal` 時由 `#require` 丟出
    @Test
    func costTWD_十進位金額相加_沒有二進位浮點誤差() throws {
        // Given
        let itemPrice = try #require(Decimal(string: "0.1"))
        let domesticShipping = try #require(Decimal(string: "0.2"))
        let expectedCostTWD = try #require(Decimal(string: "0.3"))
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: itemPrice,
            domesticShipping: domesticShipping
        )

        // When
        let costTWD = state.costTWD

        // Then
        #expect(costTWD == expectedCostTWD)
    }

    /// 相同訂單輸入下，報價與訂單摘要的總成本相同
    ///
    /// - Throws: 金額字面值無法轉成 `Decimal` 時由 `#require` 丟出
    @Test
    func costTWD_報價與相同訂單輸入_總成本一致() throws {
        // Given
        let itemPrice = try #require(Decimal(string: "1234.56"))
        let domesticShipping = try #require(Decimal(string: "66.67"))
        let internationalShippingTWD = try #require(Decimal(string: "88.88"))
        let expectedTotalCost = try #require(Decimal(string: "1451.838"))
        let cardFeePercent: Decimal = 3
        let paymentFeePercent: Decimal = 2
        let quote = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: itemPrice,
            domesticShipping: domesticShipping,
            internationalShippingTWD: internationalShippingTWD,
            cardFeePercent: cardFeePercent,
            paymentFeePercent: paymentFeePercent
        )
        let order = LedgerOrder.fixture(
            itemCost: itemPrice + domesticShipping + internationalShippingTWD,
            cardFeeRate: cardFeePercent / 100,
            paymentFeeRate: paymentFeePercent / 100,
            chargedAmount: itemPrice
        )

        // When
        let quoteTotalCost = quote.costTWD
        let orderTotalCost = OrderSummary(order: order).totalCost

        // Then
        #expect(quoteTotalCost == expectedTotalCost)
        #expect(orderTotalCost == expectedTotalCost)
    }

    /// 匯率載入失敗後按重試，重新取得匯率並恢復試算
    @Test
    @MainActor
    func retryTapped_匯率載入失敗_恢復可用匯率() async {
        // Given
        var initialState = QuoteFeature.State()
        initialState.rateSource.errorMessage = "網路連線異常，目前無法計算建議售價。"
        let fetchedBases = LockIsolated<[CurrencyCode]>([])
        let store = TestStore(initialState: initialState) {
            QuoteFeature()
        } withDependencies: {
            $0.exchangeRateService.fetchLatest = { base in
                fetchedBases.withValue {
                    $0.append(base)
                }
                return .fallback
            }
        }

        // When
        await store.send(.view(.retryTapped))

        // Then
        await store.receive(\.rateSource.refreshRequested) {
            $0.rateSource.isLoading = true
            $0.rateSource.errorMessage = nil
        }
        await store.receive(\.rateSource.ratesResponse.success) {
            $0.rateSource.isLoading = false
            $0.rateSource.snapshot = FxRateSnapshot.fallback
        }
        #expect(store.state.rateSource.hasUsableRate)
        #expect(store.state.rateSource.rateUnavailableReason == nil)
        #expect(fetchedBases.value == [.twd])
    }

    /// 匯率載入中不顯示不可用原因
    @Test
    func rateUnavailableReason_匯率載入中_不顯示不可用原因() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(isLoading: true))

        // When
        let reason = state.rateSource.rateUnavailableReason

        // Then
        #expect(reason == nil)
    }

    /// 韓元已有可用匯率時不顯示不可用原因
    @Test
    func rateUnavailableReason_已有可用匯率_不顯示不可用原因() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw, snapshot: Self.fixedSnapshot)
        )

        // When
        let reason = state.rateSource.rateUnavailableReason

        // Then
        #expect(reason == nil)
    }

    /// 缺少選定幣別匯率與錯誤訊息時顯示通用提示
    @Test
    func rateUnavailableReason_沒有匯率與錯誤訊息_顯示通用說明() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(
                fromCurrency: .krw,
                snapshot: FxRateSnapshot(
                    date: Date(timeIntervalSince1970: 0),
                    base: .usd,
                    rates: [:]
                )
            )
        )

        // When
        let reason = state.rateSource.rateUnavailableReason

        // Then
        #expect(reason == "尚無可用匯率資料，暫時無法試算。")
    }

    /// 匯率載入中再次重試不會建立第二個請求
    ///
    /// - Note: 若重送請求，`ExchangeRateService.testValue` 的 `unimplemented` 會讓測試失敗
    @Test
    @MainActor
    func retryTapped_匯率載入中_不重複送出請求() async {
        // Given
        let store = TestStore(
            initialState: QuoteFeature.State(rateSource: QuoteRateFeature.State(isLoading: true))
        ) {
            QuoteFeature()
        }

        // When
        await store.send(.view(.retryTapped))

        // Then
        await store.receive(\.rateSource.refreshRequested)
    }

    /// 畫面可試算時顯示建議售價與預估獲利
    @Test
    func displayedSuggestedTWD_匯率可用且毛利可達_顯示售價與預估獲利() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_500,
            targetMarginPercent: 25
        )

        // When
        let displayedSuggestedTWD = state.displayedSuggestedTWD
        let heroMessage = state.heroMessage

        // Then
        #expect(displayedSuggestedTWD == 2_000)
        #expect(heroMessage == .estimate(profitTWD: 500, marginPercent: 25))
    }

    /// 沒有可用匯率時隱藏售價並提示匯率不可用
    @Test
    func displayedSuggestedTWD_沒有可用匯率_隱藏售價並提示匯率不可用() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(fromCurrency: .krw))

        // When
        let displayedSuggestedTWD = state.displayedSuggestedTWD
        let heroMessage = state.heroMessage

        // Then
        #expect(displayedSuggestedTWD == nil)
        #expect(heroMessage == .rateUnavailable)
    }

    /// 目標毛利達 100% 時隱藏售價並提示毛利過高
    @Test
    func displayedSuggestedTWD_目標毛利達百分之百_隱藏售價並提示毛利過高() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_000,
            targetMarginPercent: 100
        )

        // When
        let displayedSuggestedTWD = state.displayedSuggestedTWD
        let heroMessage = state.heroMessage

        // Then
        #expect(displayedSuggestedTWD == nil)
        #expect(heroMessage == .marginTooHigh)
    }

    /// 商品價格為零時，建議售價顯示零元
    @Test
    func displayedSuggestedTWD_商品價格為零_顯示零元售價() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(fromCurrency: .twd))

        // When
        let displayedSuggestedTWD = state.displayedSuggestedTWD

        // Then
        #expect(displayedSuggestedTWD == 0)
    }

    /// 商品價格為零時算不出毛利率，hero 卡顯示毛利過高訊息
    @Test
    func heroMessage_商品價格為零_顯示毛利過高訊息() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(fromCurrency: .twd))

        // When
        let message = state.heroMessage

        // Then
        #expect(message == .marginTooHigh)
    }

    /// 已有匯率快照時，只載入幣別清單並保留快照
    @Test
    @MainActor
    func task_已有匯率快照_只載入幣別清單() async {
        // Given
        let initialState = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(snapshot: Self.fixedSnapshot)
        )
        let store = TestStore(initialState: initialState) {
            QuoteFeature()
        } withDependencies: {
            $0.currencyMetadataService.fetchCodes = {
                [.usd, .jpy]
            }
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.rateSource.task)
        await store.receive(\.rateSource.currencyCodesResponse.success) {
            $0.rateSource.availableCurrencies = [.jpy, .krw, .usd]
        }
    }

    /// 重試時匯率連線失敗，顯示網路異常的說明
    @Test
    @MainActor
    func retryTapped_匯率連線失敗_顯示網路異常訊息() async {
        // Given
        let failingFetchLatest: ExchangeRateService.FetchLatest = { _ in
            throw .transport(
                underlying: TestDependencies.makeUnderlyingError(message: "network unavailable")
            )
        }
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        } withDependencies: {
            $0.exchangeRateService.fetchLatest = failingFetchLatest
        }

        // When
        await store.send(.view(.retryTapped))

        // Then
        await store.receive(\.rateSource.refreshRequested) {
            $0.rateSource.isLoading = true
        }
        await store.receive(\.rateSource.ratesResponse.failure) {
            $0.rateSource.isLoading = false
            $0.rateSource.errorMessage = "網路連線異常，目前無法計算建議售價。"
        }
    }
}
