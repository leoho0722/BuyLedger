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

/// `QuoteFeature` 的單元測試，涵蓋報價試算的成本與建議售價計算、幣別切換、匯率重試與畫面狀態
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

    /// 驗證未帶參數建立 State 時，來源幣別預設為韓元，所有金額與費率輸入都是零
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

    /// 驗證來源為韓元且帶有匯率與刷卡費時，商品折算金額與刷卡費加總為總成本
    @Test
    func costTWD_含來源幣別匯率與刷卡費_加總總成本() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw, snapshot: Self.fixedSnapshot),
            itemPrice: 100_000,
            cardFeePercent: 2
        )

        // When
        let costTWD = state.costTWD

        // Then
        #expect(costTWD == 816_000)
    }

    /// 驗證商品價格為 100,000 韓元且匯率為每韓元 8 元時，折算商品金額為 800,000 元
    @Test
    func itemTWD_含韓圓匯率_折算商品金額() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw, snapshot: Self.fixedSnapshot),
            itemPrice: 100_000,
            cardFeePercent: 2
        )

        // When
        let itemTWD = state.itemTWD

        // Then
        #expect(itemTWD == 800_000)
    }

    /// 驗證商品折算為 800,000 元且刷卡費為 2% 時，刷卡費為 16,000 元
    @Test
    func cardFeeTWD_含匯率與刷卡費_計入刷卡費() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw, snapshot: Self.fixedSnapshot),
            itemPrice: 100_000,
            cardFeePercent: 2
        )

        // When
        let cardFeeTWD = state.cardFeeTWD

        // Then
        #expect(cardFeeTWD == 16_000)
    }

    /// 驗證沒有匯率快照時，總成本只保留以新台幣輸入的國際運費 180 元
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
        let costTWD = state.costTWD

        // Then
        #expect(costTWD == 180)
    }

    /// 驗證來源為韓元但沒有匯率快照時，商品金額無法折算而回傳零
    @Test
    func itemTWD_沒有匯率快照_折算為零() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw),
            itemPrice: 100_000,
            domesticShipping: 5_000,
            internationalShippingTWD: 180,
            cardFeePercent: 2.5
        )

        // When
        let value = state.itemTWD

        // Then
        #expect(value == 0)
    }

    /// 驗證來源為韓元但沒有匯率快照時，國內運費無法折算而回傳零
    @Test
    func domesticTWD_沒有匯率快照_折算為零() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw),
            itemPrice: 100_000,
            domesticShipping: 5_000,
            internationalShippingTWD: 180,
            cardFeePercent: 2.5
        )

        // When
        let value = state.domesticTWD

        // Then
        #expect(value == 0)
    }

    /// 驗證來源為韓元但沒有匯率快照時，刷卡費無法折算而回傳零
    @Test
    func cardFeeTWD_沒有匯率快照_折算為零() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .krw),
            itemPrice: 100_000,
            domesticShipping: 5_000,
            internationalShippingTWD: 180,
            cardFeePercent: 2.5
        )

        // When
        let value = state.cardFeeTWD

        // Then
        #expect(value == 0)
    }

    /// 驗證成本為 100 元且目標毛利為 25% 時，建議售價無條件進位到十元
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

        // Then
        // 成本 100 / (1 - 0.25) = 133.33，無條件進位到 140
        #expect(suggestedTWD == 140)
    }

    /// 驗證目標毛利為 25% 時，以建議售價 140 元扣除成本 100 元，預估獲利為 40 元
    @Test
    func estimatedProfitTWD_目標毛利為四分之一_回傳建議售價減成本() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 100,
            targetMarginPercent: 25
        )

        // When
        let estimatedProfitTWD = state.estimatedProfitTWD

        // Then
        #expect(estimatedProfitTWD == 40)
    }

    /// 驗證來源幣別由韓元切換為新台幣時，商品金額以 1:1 折算，新台幣金額與輸入值相同
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

    /// 驗證目標毛利由 10% 改為 50% 時，建議售價依新比例重算為 2000
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

    /// 驗證商品金額輸入負數時，金額夾限為零，不保留負值
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

    /// 驗證點選幣別按鈕時，若幣別選擇畫面未開啟，`rateSource.destination` 改為 `.currencyPicker`
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

    /// 驗證幣別選擇畫面開啟中選取 TWD 時，來源幣別改為 TWD，並清除 `rateSource.destination` 以關閉畫面
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

    /// 驗證商品成本為 1,000 元，目標毛利為 0%、30% 或 50% 時，建議售價符合各案例的指定值
    ///
    /// - Parameter scenario: 目標毛利 (%) 與預期的建議售價 (TWD)
    @Test(arguments: [
        MarginFormulaScenario(targetMarginPercent: 0, expectedSuggestedTWD: 1_000),
        MarginFormulaScenario(targetMarginPercent: 30, expectedSuggestedTWD: 1_430),
        MarginFormulaScenario(targetMarginPercent: 50, expectedSuggestedTWD: 2_000),
    ])
    func suggestedTWD_毛利公式範例_售價符合公式(scenario: MarginFormulaScenario) {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_000,
            targetMarginPercent: Decimal(scenario.targetMarginPercent)
        )

        // When
        let suggestedTWD = state.suggestedTWD

        // Then
        #expect(suggestedTWD == Decimal(scenario.expectedSuggestedTWD))
    }

    /// 驗證建議售價進位後，預估毛利率介於目標毛利與目標加 1 個百分點之間
    ///
    /// - Parameter scenario: 毛利公式案例的目標毛利 (%)
    /// - Throws: 算不出預估毛利率時由 `#require` 丟出
    @Test(arguments: [
        MarginFormulaScenario(targetMarginPercent: 0, expectedSuggestedTWD: 1_000),
        MarginFormulaScenario(targetMarginPercent: 30, expectedSuggestedTWD: 1_430),
        MarginFormulaScenario(targetMarginPercent: 50, expectedSuggestedTWD: 2_000),
    ])
    func estimatedMarginPercent_毛利公式範例_符合目標毛利範圍(scenario: MarginFormulaScenario) throws {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_000,
            targetMarginPercent: Decimal(scenario.targetMarginPercent)
        )

        // When
        let estimatedMarginPercent = state.estimatedMarginPercent

        // Then
        let marginPercent = try #require(estimatedMarginPercent)
        #expect(marginPercent >= Decimal(scenario.targetMarginPercent))
        #expect(marginPercent < Decimal(scenario.targetMarginPercent + 1))
    }

    /// 驗證目標毛利低於 100% 時提供建議售價，達到或超過 100% 時不提供
    ///
    /// - Parameter scenario: 要設定的目標毛利 (%) 與預期是否提供建議售價
    @Test(arguments: [
        MarginThresholdScenario(targetMarginPercent: 99, hasSuggestedPrice: true),
        MarginThresholdScenario(targetMarginPercent: 100, hasSuggestedPrice: false),
        MarginThresholdScenario(targetMarginPercent: 150, hasSuggestedPrice: false),
    ])
    @MainActor
    func binding_目標毛利在百分之百前後_依門檻決定是否提供建議售價(scenario: MarginThresholdScenario) async {
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
        await store.send(\.binding.targetMarginPercent, Decimal(scenario.targetMarginPercent)) {
            $0.targetMarginPercent = Decimal(scenario.targetMarginPercent)
        }

        // Then
        #expect((store.state.suggestedTWD != nil) == scenario.hasSuggestedPrice)
    }

    /// 驗證商品金額 0.1 加國內運費 0.2 的總成本精確等於 0.3，不因二進位浮點產生誤差
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

    /// 驗證報價包含商品、國內運費、國際運費及兩種費率時，總成本為 1451.838
    ///
    /// - Throws: 金額字面值無法轉成 `Decimal` 時由 `#require` 丟出
    @Test
    func costTWD_與訂單相同輸入_回傳指定總成本() throws {
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

        // When
        let quoteTotalCost = quote.costTWD

        // Then
        #expect(quoteTotalCost == expectedTotalCost)
    }

    /// 驗證訂單包含與報價相同的成本及兩種費率時，總成本為 1451.838
    ///
    /// - Throws: 金額字面值無法轉成 `Decimal` 時由 `#require` 丟出
    @Test
    func totalCost_與報價相同輸入_回傳指定總成本() throws {
        // Given
        let itemPrice = try #require(Decimal(string: "1234.56"))
        let domesticShipping = try #require(Decimal(string: "66.67"))
        let internationalShippingTWD = try #require(Decimal(string: "88.88"))
        let expectedTotalCost = try #require(Decimal(string: "1451.838"))
        let cardFeePercent: Decimal = 3
        let paymentFeePercent: Decimal = 2
        let order = LedgerOrder.fixture(
            itemCost: itemPrice + domesticShipping + internationalShippingTWD,
            cardFeeRate: cardFeePercent / 100,
            paymentFeeRate: paymentFeePercent / 100,
            chargedAmount: itemPrice
        )
        let summary = OrderSummary(order: order)

        // When
        let orderTotalCost = summary.totalCost

        // Then
        #expect(orderTotalCost == expectedTotalCost)
    }

    /// 驗證匯率載入失敗後按重試，以新台幣為基準重新抓取匯率，成功後恢復可用並清除錯誤訊息
    @Test
    @MainActor
    func retryTapped_匯率載入失敗_恢復可用匯率() async {
        // Given
        var initialState = QuoteFeature.State()
        initialState.rateSource.errorMessage = "quote.calculator.message.networkErrorOccurred"
        let fetchedBases = LockIsolated<[CurrencyCode]>([])
        let store = TestStore(initialState: initialState) {
            QuoteFeature()
        } withDependencies: {
            $0.exchangeRateService.fetchLatest = { base in
                fetchedBases.withValue {
                    $0.append(base)
                }
                return Self.fixedSnapshot
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
            $0.rateSource.snapshot = Self.fixedSnapshot
        }
        #expect(store.state.rateSource.hasUsableRate)
        #expect(store.state.rateSource.rateUnavailableReason == nil)
        #expect(fetchedBases.value == [.twd])
    }

    /// 驗證匯率載入中時，不可用原因為 `nil`，畫面不顯示提示
    @Test
    func rateUnavailableReason_匯率載入中_不顯示不可用原因() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(isLoading: true))

        // When
        let reason = state.rateSource.rateUnavailableReason

        // Then
        #expect(reason == nil)
    }

    /// 驗證來源為韓元且已有可用匯率時，不可用原因為 `nil`
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

    /// 驗證快照缺少所選幣別匯率且沒有錯誤訊息時，不可用原因回傳通用的匯率說明文案
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
        #expect(reason == "quote.calculator.message.exchangeRateAvailable")
    }

    /// 驗證匯率載入中再按重試時，狀態不變且不重複呼叫匯率服務
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

    /// 驗證匯率可用且目標毛利為 25% 時，成本 1,500 元的畫面建議售價為 2,000 元
    @Test
    func displayedSuggestedTWD_匯率可用且毛利可達_顯示建議售價() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_500,
            targetMarginPercent: 25
        )

        // When
        let displayedSuggestedTWD = state.displayedSuggestedTWD

        // Then
        #expect(displayedSuggestedTWD == 2_000)
    }

    /// 驗證匯率可用且目標毛利為 25% 時，預估結果包含獲利 500 元與毛利率 25%
    @Test
    func heroMessage_匯率可用且毛利可達_顯示預估獲利() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_500,
            targetMarginPercent: 25
        )

        // When
        let heroMessage = state.heroMessage

        // Then
        #expect(heroMessage == .estimate(profitTWD: 500, marginPercent: 25))
    }

    /// 驗證來源為韓元但沒有可用匯率時，畫面不顯示建議售價
    @Test
    func displayedSuggestedTWD_沒有可用匯率_隱藏建議售價() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(fromCurrency: .krw))

        // When
        let displayedSuggestedTWD = state.displayedSuggestedTWD

        // Then
        #expect(displayedSuggestedTWD == nil)
    }

    /// 驗證來源為韓元但沒有可用匯率時，預估結果顯示匯率不可用的提示
    @Test
    func heroMessage_沒有可用匯率_提示匯率不可用() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(fromCurrency: .krw))

        // When
        let heroMessage = state.heroMessage

        // Then
        #expect(heroMessage == .rateUnavailable)
    }

    /// 驗證目標毛利達 100% 時，畫面不顯示建議售價
    @Test
    func displayedSuggestedTWD_目標毛利達百分之百_隱藏建議售價() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_000,
            targetMarginPercent: 100
        )

        // When
        let displayedSuggestedTWD = state.displayedSuggestedTWD

        // Then
        #expect(displayedSuggestedTWD == nil)
    }

    /// 驗證目標毛利達 100% 而無法提供建議售價時，預估結果顯示毛利過高的提示
    @Test
    func heroMessage_目標毛利達百分之百_提示毛利過高() {
        // Given
        let state = QuoteFeature.State(
            rateSource: QuoteRateFeature.State(fromCurrency: .twd),
            itemPrice: 1_000,
            targetMarginPercent: 100
        )

        // When
        let heroMessage = state.heroMessage

        // Then
        #expect(heroMessage == .marginTooHigh)
    }

    /// 驗證商品價格為零時，畫面的建議售價顯示為 0，不隱藏
    @Test
    func displayedSuggestedTWD_商品價格為零_顯示零元售價() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(fromCurrency: .twd))

        // When
        let displayedSuggestedTWD = state.displayedSuggestedTWD

        // Then
        #expect(displayedSuggestedTWD == 0)
    }

    /// 驗證商品價格為零時算不出毛利率，hero 卡改為毛利過高的提示
    @Test
    func heroMessage_商品價格為零_顯示毛利過高訊息() {
        // Given
        let state = QuoteFeature.State(rateSource: QuoteRateFeature.State(fromCurrency: .twd))

        // When
        let message = state.heroMessage

        // Then
        #expect(message == .marginTooHigh)
    }

    /// 驗證已有匯率快照時，`task` 只載入幣別清單，不重新抓取匯率，快照維持原樣
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

    /// 驗證重試時匯率連線失敗，載入狀態結束，錯誤訊息改為網路異常的說明
    @Test
    @MainActor
    func retryTapped_匯率連線失敗_顯示網路異常訊息() async {
        // Given
        let failingFetchLatest: ExchangeRateService.FetchLatest = { _ throws(APIError) in
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
            $0.rateSource.errorMessage = "quote.calculator.message.networkErrorOccurred"
        }
    }
}

// MARK: - Nested Types

extension QuoteFeatureTests {

    /// 毛利公式測試的參數案例，帶入目標毛利與預期的建議售價
    struct MarginFormulaScenario: Sendable {

        /// 目標毛利 (%)
        let targetMarginPercent: Int

        /// 預期的建議售價 (TWD)
        let expectedSuggestedTWD: Int
    }

    /// 百分之百門檻測試的參數案例，帶入目標毛利與預期是否提供建議售價
    struct MarginThresholdScenario: Sendable {

        /// 要設定的目標毛利 (%)
        let targetMarginPercent: Int

        /// 預期是否提供建議售價
        let hasSuggestedPrice: Bool
    }
}
