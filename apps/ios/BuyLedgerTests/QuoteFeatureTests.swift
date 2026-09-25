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
@MainActor
struct QuoteFeatureTests {

    // MARK: - Properties

    /// 供計算測試使用的固定匯率快照
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

    /// 驗證預設狀態的輸入值皆為零
    @Test func defaultStateStartsAtZero() {
        // Given
        let state = QuoteFeature.State()

        // When
        let values = (
            state.rateSource.fromCurrency,
            state.itemPrice,
            state.domesticShipping,
            state.internationalShippingTWD,
            state.cardFeePercent,
            state.targetMarginPercent
        )

        // Then
        #expect(values.0 == .krw)
        #expect(values.1 == 0)
        #expect(values.2 == 0)
        #expect(values.3 == 0)
        #expect(values.4 == 0)
        #expect(values.5 == 0)
    }

    /// 驗證成本計算會使用快照匯率與刷卡手續費
    @Test func costCalculationUsesRateAndCardFee() {
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

    /// 驗證沒有匯率快照時只有國際運費保留在成本
    @Test func costCalculationIsZeroWithoutSnapshot() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw),
            itemPrice: 100_000,
            domesticShipping: 5_000,
            internationalShippingTWD: 180,
            cardFeePercent: 2.5,
            targetMarginPercent: 25
        )

        // When
        let itemTWD = state.itemTWD
        let domesticTWD = state.domesticTWD
        let cardFeeTWD = state.cardFeeTWD
        let costTWD = state.costTWD

        // Then
        #expect(state.rateSource.snapshot == nil)
        #expect(state.rateSource.hasUsableRate == false)
        #expect(itemTWD == 0)
        #expect(domesticTWD == 0)
        #expect(cardFeeTWD == 0)
        #expect(costTWD == 180)
    }

    /// 驗證建議售價會無條件進位到十元
    @Test func suggestedPriceRoundsUpToNearestTen() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 100,
            targetMarginPercent: 25
        )

        // When
        let costTWD = state.costTWD
        let suggestedTWD = state.suggestedTWD
        let estimatedProfitTWD = state.estimatedProfitTWD

        // Then
        // 成本 100 / (1 - 0.25) = 133.33，無條件進位到 140
        #expect(costTWD == 100)
        #expect(suggestedTWD == 140)
        #expect(estimatedProfitTWD == 40)
    }

    /// 驗證切換為新台幣後商品本金維持原值
    @Test func switchingCurrencyRecomputesItemTWD() async {
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
        await store.receive(\.rateSource.currencySelected) {
            $0.rateSource.fromCurrency = .twd
        }

        // Then
        #expect(store.state.itemTWD == 150_000)
    }

    /// 驗證目標毛利變更會更新建議售價
    @Test func bindingMarginUpdatesSuggestedPrice() async {
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

    /// 驗證數值 binding 會把負值限制為零
    @Test func negativeInputsClampToZeroOnBinding() async {
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
        #expect(store.state.targetMarginPercent == 30)
    }

    /// 驗證點擊幣別列會呈現選擇目的地
    @Test func currencyPickerTappedPresentsDestination() async {
        // Given
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        }

        // When
        await store.send(.view(.currencyPickerTapped))
        await store.receive(\.rateSource.pickerTapped) {
            $0.rateSource.destination = .currencyPicker
        }

        // Then
        #expect(store.state.rateSource.destination != nil)
    }

    /// 驗證選定幣別後更新來源幣別並關閉目的地
    @Test func currencySelectedUpdatesCurrencyAndDismissesDestination() async {
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
        await store.receive(\.rateSource.currencySelected) {
            $0.rateSource.fromCurrency = .twd
            $0.rateSource.destination = nil
        }

        // Then
        #expect(store.state.rateSource.fromCurrency == .twd)
        #expect(store.state.rateSource.destination == nil)
    }

    /// 驗證毛利公式的三組代表值
    @Test(arguments: [0, 30, 50])
    func suggestedPriceMatchesGrossMarginFormulaExamples(targetMarginPercent: Int) {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_000,
            targetMarginPercent: Decimal(targetMarginPercent)
        )

        // When
        let suggestedTWD = state.suggestedTWD

        // Then
        switch targetMarginPercent {
        case 0:
            #expect(suggestedTWD == 1_000)
            #expect(state.estimatedMarginPercent == 0)
        case 30:
            #expect(suggestedTWD == 1_430)
            #expect(abs((state.estimatedMarginPercent ?? 0) - 30) < 1)
        case 50:
            #expect(suggestedTWD == 2_000)
            #expect(state.estimatedMarginPercent == 50)
        default:
            Issue.record("未涵蓋的毛利測試案例")
        }
    }

    /// 驗證 100% 以上與 80% 目標毛利的顯示狀態
    @Test(arguments: [(100, false), (150, false), (80, true)])
    func targetMarginAtOrAboveOneHundredPercentYieldsExpectedPrice(
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
        await store.send(
            \.binding.targetMarginPercent,
            Decimal(targetMarginPercent)
        ) {
            $0.targetMarginPercent = Decimal(targetMarginPercent)
        }

        // Then
        #expect((store.state.suggestedTWD != nil) == hasSuggestedPrice)
        #expect(store.state.targetMarginPercent == Decimal(targetMarginPercent))
    }

    /// 驗證 Decimal 相加不會產生二進位浮點誤差
    @Test func decimalTypeAvoidsBinaryFloatingPointDrift() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: Decimal(string: "0.1")!,
            domesticShipping: Decimal(string: "0.2")!
        )

        // When
        let totalTWD = state.itemTWD + state.domesticTWD

        // Then
        #expect(totalTWD == Decimal(string: "0.3")!)
    }

    /// 驗證報價成本與訂單摘要在相同輸入下相等
    @Test func quoteCostAgreesWithOrderTotalCostForMatchingInputs() {
        // Given
        let itemPrice = Decimal(string: "1234.56")!
        let domesticShipping = Decimal(string: "66.67")!
        let internationalShippingTWD = Decimal(string: "88.88")!
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
        let orderTotalCost = OrderSummary(order: order).totalCost

        // Then
        #expect(quote.costTWD == orderTotalCost)
    }

    /// 驗證匯率載入失敗後重試可恢復內容
    @Test func failedRateLoadExplainsReasonAndRetryRestoresContent() async {
        // Given
        let client = QuoteRateClientStub()
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        } withDependencies: {
            $0[ExchangeRateClient.self].fetchLatest = {
                (base: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                try await client.fetchLatest(base)
            }
            $0[CurrencyMetadataRepository.self].fetchCodes = { [] }
        }

        // When
        await store.send(.view(.task))
        await store.receive(\.rateSource.task) {
            $0.rateSource.isLoading = true
            $0.rateSource.errorMessage = nil
        }
        await store.receive(\.rateSource.currencyCodesResponse.success)
        await store.receive(\.rateSource.ratesResponse.failure) {
            $0.rateSource.isLoading = false
            $0.rateSource.errorMessage = "網路連線異常，目前無法計算建議售價。"
        }
        await store.send(.view(.retryTapped))
        await store.receive(\.rateSource.refreshRequested) {
            $0.rateSource.isLoading = true
            $0.rateSource.errorMessage = nil
        }
        await store.receive(\.rateSource.ratesResponse.success) {
            $0.rateSource.isLoading = false
            $0.rateSource.snapshot = FxRateSnapshot.fallback
            $0.rateSource.errorMessage = nil
        }

        // Then
        #expect(store.state.rateSource.hasUsableRate)
        #expect(store.state.rateSource.rateUnavailableReason == nil)
        #expect(await client.callCount == 2)
    }

    /// 驗證載入中不顯示匯率不可用原因
    @Test func rateUnavailableReasonIsNilWhileLoading() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(isLoading: true))

        // When
        let reason = state.rateSource.rateUnavailableReason

        // Then
        #expect(reason == nil)
    }

    /// 驗證有可用匯率時不顯示匯率不可用原因
    @Test func rateUnavailableReasonIsNilWhenRateIsUsable() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(
                fromCurrency: .twd,
                snapshot: FxRateSnapshot.fallback
            )
        )

        // When
        let reason = state.rateSource.rateUnavailableReason

        // Then
        #expect(state.rateSource.hasUsableRate)
        #expect(reason == nil)
    }

    /// 驗證缺少選定幣別匯率時使用通用提示
    @Test func rateUnavailableReasonFallsBackToGenericMessageWithoutAnErrorMessage() {
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
        #expect(state.rateSource.hasUsableRate == false)
        #expect(state.rateSource.errorMessage == nil)
        #expect(reason == "尚無可用匯率資料，暫時無法試算。")
    }

    /// 驗證載入中再次重試不會建立第二個請求
    @Test func retryTappedIsNoOpWhileAlreadyLoading() async {
        // Given
        let store = TestStore(
            initialState: QuoteFeature.State(rateSource: QuoteRateFeature.State(isLoading: true))
        ) {
            QuoteFeature()
        }

        // When
        await store.send(.view(.retryTapped))
        await store.receive(\.rateSource.refreshRequested)

        // Then
        #expect(store.state.rateSource.isLoading)
    }

    /// 驗證建議售價與 hero 訊息的三種狀態
    @Test(arguments: ["calculable", "ratesUnavailable", "marginTooHigh"])
    func displayedSuggestedTWDAndHeroMessage(scenario: String) {
        // Given
        let state: QuoteFeature.State
        switch scenario {
        case "calculable":
            state = QuoteFeature.State(
                rateSource: QuoteRateFeature.State(fromCurrency: .twd),
                itemPrice: 1_000,
                targetMarginPercent: 25
            )
        case "ratesUnavailable":
            state = QuoteFeature.State(rateSource: QuoteRateFeature.State(fromCurrency: .krw))
        case "marginTooHigh":
            state = QuoteFeature.State(
                rateSource: QuoteRateFeature.State(fromCurrency: .twd),
                itemPrice: 1_000,
                targetMarginPercent: 100
            )
        default:
            Issue.record("未涵蓋的 hero 測試案例")
            return
        }

        // When
        let displayedSuggestedTWD = state.displayedSuggestedTWD
        let heroMessage = state.heroMessage

        // Then
        switch scenario {
        case "calculable":
            #expect(displayedSuggestedTWD == 1_340)
            if case let .estimate(profitTWD, _) = heroMessage {
                #expect(profitTWD == 340)
            } else {
                Issue.record("可試算狀態應顯示預估獲利")
            }
        case "ratesUnavailable":
            #expect(displayedSuggestedTWD == nil)
            #expect(heroMessage == .rateUnavailable)
        case "marginTooHigh":
            #expect(displayedSuggestedTWD == nil)
            #expect(heroMessage == .marginTooHigh)
        default:
            Issue.record("未涵蓋的 hero 測試案例")
        }
    }

    /// 驗證商品價格為零時沿用無法計算預估獲利的既有語意
    @Test func heroMessageForZeroPriceUsesMarginTooHigh() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(fromCurrency: .twd))

        // When
        let message = state.heroMessage

        // Then
        #expect(state.displayedSuggestedTWD == 0)
        #expect(state.estimatedMarginPercent == nil)
        #expect(message == .marginTooHigh)
    }
}

// MARK: - Nested Types

extension QuoteFeatureTests {

    /// 測試用的匯率 client
    actor QuoteRateClientStub {

        /// 已呼叫匯率 client 的次數
        private(set) var callCount = 0
    }
}

// MARK: - Internal Method

extension QuoteFeatureTests.QuoteRateClientStub {

    /// 取得下一筆匯率快照；第一次呼叫模擬網路失敗
    ///
    /// - Parameter base: 匯率的基準幣別
    /// - Returns: 固定的 fallback 匯率快照
    /// - Throws: 第一次呼叫時拋出模擬的 transport error
    func fetchLatest(_: CurrencyCode) async throws(APIError) -> FxRateSnapshot {
        callCount += 1
        if callCount == 1 {
            throw APIError.transport(
                underlying: TestDependencies.makeUnderlyingError(message: "network unavailable")
            )
        }
        return FxRateSnapshot.fallback
    }
}
