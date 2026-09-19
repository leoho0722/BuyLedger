//
//  QuoteFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/05/02.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
/// 驗證報價試算流程
struct QuoteFeatureTests {

    // MARK: - Tests

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func defaultStateStartsAtZero() {
        // Given

        // 預設值全為 0：頁面剛開時不預填示範金額或費率
        // 避免讓使用者誤以為畫面上的「建議售價」是已存在的試算結果
        let state = QuoteFeature.State()

        // When

        let fromCurrency = state.fromCurrency
        let itemPrice = state.itemPrice
        let domesticShipping = state.domesticShipping
        let internationalShippingTwd = state.internationalShippingTwd
        let cardFeePercent = state.cardFeePercent
        let targetMarginPercent = state.targetMarginPercent

        // Then

        #expect(fromCurrency == .krw)
        #expect(itemPrice == 0)
        #expect(domesticShipping == 0)
        #expect(internationalShippingTwd == 0)
        #expect(cardFeePercent == 0)
        #expect(targetMarginPercent == 0)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func costCalculationUsesRateAndCardFee() {
        // Given

        // 注入 fallback snapshot 模擬 API 已回應；runtime 已不再使用 hardcoded fallback
        let state = QuoteFeature.State(
            fromCurrency: .krw,
            itemPrice: 100_000,
            domesticShipping: 0,
            internationalShippingTwd: 0,
            cardFeePercent: 0,
            targetMarginPercent: 0,
            snapshot: FxRateSnapshot.fallback
        )

        // 用 snapshot 匯率計算 KRW，結果需允許極小 Decimal 捨入誤差
        let tolerance = Decimal(string: "1e-20")!
        // When

        let itemTwd = state.itemTwd
        let costTwd = state.costTwd

        // Then

        #expect(abs(itemTwd - 2_280) < tolerance)
        #expect(abs(costTwd - 2_280) < tolerance)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func costCalculationIsZeroWithoutSnapshot() {
        // Given

        // 沒有匯率資料時，衍生金額歸零並顯示提示。
        let state = QuoteFeature.State(
            fromCurrency: .krw,
            itemPrice: 100_000,
            domesticShipping: 5_000,
            internationalShippingTwd: 180,
            cardFeePercent: 2.5,
            targetMarginPercent: 25
        )

        // When

        let snapshot = state.snapshot
        let hasUsableRate = state.hasUsableRate
        let itemTwd = state.itemTwd
        let domesticTwd = state.domesticTwd
        let cardFeeTwd = state.cardFeeTwd
        let costTwd = state.costTwd

        // Then

        #expect(snapshot == nil)
        #expect(hasUsableRate == false)
        // 國際運費以 TWD 計算，其他項目因匯率不可用而為零。
        #expect(itemTwd == 0)
        #expect(domesticTwd == 0)
        #expect(cardFeeTwd == 0)
        // costTwd = 0 + 0 + 180 + 0 = 180
        #expect(costTwd == 180)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func suggestedPriceRoundsUpToNearestTen() {
        // Given

        let state = QuoteFeature.State(
            fromCurrency: .twd,
            itemPrice: 100,
            domesticShipping: 0,
            internationalShippingTwd: 0,
            cardFeePercent: 0,
            targetMarginPercent: 25
        )

        // 真毛利 1000 / 0.75 = 133.33，無條件進位到 140
        // When

        let costTwd = state.costTwd
        let suggestedTwd = state.suggestedTwd
        let estimatedProfitTwd = state.estimatedProfitTwd

        // Then

        #expect(costTwd == 100)
        #expect(suggestedTwd == 140)
        #expect(estimatedProfitTwd == 40)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func switchingCurrencyRecomputesItemTwd() async {
        // Given

        // 使用非零單價驗證匯率切換對 itemTwd 的影響。
        let store = TestStore(initialState: QuoteFeature.State(itemPrice: 150_000)) {
            QuoteFeature()
        }

        // When

        await store.send(\.binding.fromCurrency, .twd) {
            $0.fromCurrency = .twd
        }

        // TWD rate = 1, so itemTwd == itemPrice
        // Then

        #expect(store.state.itemTwd == 150_000)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func bindingMarginUpdatesSuggestedPrice() async {
        // Given

        let initial = QuoteFeature.State(
            fromCurrency: .twd,
            itemPrice: 1_000,
            domesticShipping: 0,
            internationalShippingTwd: 0,
            cardFeePercent: 0,
            targetMarginPercent: 10
        )
        let store = TestStore(initialState: initial) {
            QuoteFeature()
        }

        // cost / (1 − 0.10) = 1111.11...，無條件進位到十元 → 1120
        // When

        let initialSuggestedTwd = store.state.suggestedTwd

        // Then

        #expect(initialSuggestedTwd == 1_120)

        // When

        await store.send(\.binding.targetMarginPercent, 50) {
            // Then

            $0.targetMarginPercent = 50
        }

        // cost / (1 − 0.50) = 2000，本身即十元整數
        // Then

        #expect(store.state.suggestedTwd == 2_000)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func negativeInputsClampToZeroOnBinding() async {
        // Given

        // 所有數值欄位都由 reducer 限制為非負
        let store = TestStore(
            initialState: QuoteFeature.State(
                fromCurrency: .twd,
                itemPrice: 500,
                targetMarginPercent: 30
            )
        ) {
            QuoteFeature()
        }

        // 負的本金 → 0
        // When

        await store.send(\.binding.itemPrice, -100) {
            $0.itemPrice = 0
        }

        // 負的目標毛利 → 0 (目標毛利僅保證非負、不設上限)
        await store.send(\.binding.targetMarginPercent, -5) {
            $0.targetMarginPercent = 0
        }

        // 正值不受影響
        await store.send(\.binding.domesticShipping, 250) {
            $0.domesticShipping = 250
        }
        // Then

        #expect(store.state.itemPrice == 0)
        #expect(store.state.targetMarginPercent == 0)
        #expect(store.state.domesticShipping == 250)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func bindingTogglesCurrencySheet() async {
        // Given

        // 幣別 sheet 狀態由 State 管理，binding 不受 clamp 影響。
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        }

        // When

        await store.send(\.binding.showsCurrencySheet, true) {
            // Then

            $0.showsCurrencySheet = true
        }
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func currencyPickerTappedShowsSheet() async {
        // Given

        // 點擊來源幣別列 → reducer 開啟幣別選擇 sheet，View 不再直接寫入 store
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        }

        // When

        await store.send(.currencyPickerTapped) {
            // Then

            $0.showsCurrencySheet = true
        }
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func fromCurrencySelectedUpdatesCurrencyAndRecomputesItemTwd() async {
        // Given

        // 選幣別後重算衍生金額
        let store = TestStore(initialState: QuoteFeature.State(itemPrice: 150_000)) {
            QuoteFeature()
        }

        // When

        await store.send(.fromCurrencySelected("TWD")) {
            $0.fromCurrency = .twd
        }

        // TWD rate = 1, so itemTwd == itemPrice
        // Then

        #expect(store.state.itemTwd == 150_000)
    }

    // MARK: - Gross Margin Formula

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func suggestedPriceMatchesGrossMarginFormulaExamples() throws(any Error) {
        // Given

        // 50% 目標毛利應得到 2 倍成本，區分毛利率與加成率公式。
        // When

        let zero = QuoteFeature.State(fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 0)
        let thirty = QuoteFeature.State(
            fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 30)
        let thirtyMargin = try #require(thirty.estimatedMarginPercent)
        let fifty = QuoteFeature.State(
            fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 50)

        // Then

        #expect(zero.suggestedTwd == 1_000)
        #expect(zero.estimatedMarginPercent == 0)

        // 成本 1000、目標毛利 30% 時，建議售價應為 1430
        #expect(thirty.suggestedTwd == 1_430)
        // 容許因售價捨入造成的些微落差 (捨入前的精確毛利率就是 30%)
        #expect(abs(thirtyMargin - 30) < 1)

        #expect(fifty.suggestedTwd == 2_000)
        #expect(fifty.estimatedMarginPercent == 50)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func targetMarginAtOrAboveOneHundredPercentYieldsNoPrice() async {
        // Given

        // 100% 以上無法計算，三個結果都應隱藏，輸入值不夾住。
        let store = TestStore(
            initialState: QuoteFeature.State(
                fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 50)
        ) {
            QuoteFeature()
        }

        // 低於 100%：三個數字皆有值
        // When

        let initialBelowOneHundred = store.state.isTargetMarginBelowOneHundredPercent
        let initialSuggestedTwd = store.state.suggestedTwd
        let initialEstimatedProfitTwd = store.state.estimatedProfitTwd
        let initialEstimatedMarginPercent = store.state.estimatedMarginPercent

        // Then

        #expect(initialBelowOneHundred == true)
        #expect(initialSuggestedTwd != nil)
        #expect(initialEstimatedProfitTwd != nil)
        #expect(initialEstimatedMarginPercent != nil)

        // 恰為 100%：三個數字一起消失，輸入值本身不被夾住
        await store.send(\.binding.targetMarginPercent, 100) {
            $0.targetMarginPercent = 100
        }
        #expect(store.state.targetMarginPercent == 100)
        #expect(store.state.isTargetMarginBelowOneHundredPercent == false)
        #expect(store.state.suggestedTwd == nil)
        #expect(store.state.estimatedProfitTwd == nil)
        #expect(store.state.estimatedMarginPercent == nil)

        // 超過 100% 時不顯示，並保留原輸入值。
        await store.send(\.binding.targetMarginPercent, 150) {
            $0.targetMarginPercent = 150
        }
        #expect(store.state.targetMarginPercent == 150)
        #expect(store.state.suggestedTwd == nil)

        // 降回 100% 以下：三個數字一起恢復
        await store.send(\.binding.targetMarginPercent, 80) {
            $0.targetMarginPercent = 80
        }
        #expect(store.state.suggestedTwd != nil)
        #expect(store.state.estimatedProfitTwd != nil)
        #expect(store.state.estimatedMarginPercent != nil)
    }

    // MARK: - Decimal Precision

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func decimalTypeAvoidsBinaryFloatingPointDrift() {
        // Given

        // Decimal 應精確得到 0.3，避免 Double 的二進位誤差。
        let state = QuoteFeature.State(
            fromCurrency: .twd,
            itemPrice: Decimal(string: "0.1")!,
            domesticShipping: Decimal(string: "0.2")!
        )

        // When

        let totalTwd = state.itemTwd + state.domesticTwd

        // Then

        #expect(totalTwd == Decimal(string: "0.3")!)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func quoteCostAgreesWithOrderTotalCostForMatchingInputs() {
        // Given

        // 報價與訂單在相同輸入下應算出相同金額
        let itemPrice = Decimal(string: "1234.56")!
        let domesticShipping = Decimal(string: "66.67")!
        let internationalShippingTwd = Decimal(string: "88.88")!
        let cardFeePercent: Decimal = 3
        let paymentFeePercent: Decimal = 2

        let quote = QuoteFeature.State(
            fromCurrency: .twd,
            itemPrice: itemPrice,
            domesticShipping: domesticShipping,
            internationalShippingTwd: internationalShippingTwd,
            cardFeePercent: cardFeePercent,
            paymentFeePercent: paymentFeePercent,
            platformFeePercent: 0
        )

        // 訂單的成本與手續費基準需和 quote 相同
        let order = LedgerOrder(
            id: "BL-QUOTE-PARITY",
            customer: LedgerCustomer(name: "報價比對", initials: "QP", tier: .regular),
            status: .quoting,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_145_600),
            items: [],
            itemCost: itemPrice + domesticShipping + internationalShippingTwd,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: cardFeePercent / 100,
            platformFeeRate: 0,
            paymentFeeRate: paymentFeePercent / 100,
            chargedAmount: itemPrice,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: ["測試"],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        // When

        let orderTotalCost = OrderSummary(order: order).totalCost

        // Then

        #expect(quote.costTwd == orderTotalCost)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func failedRateLoadExplainsReasonAndRetryRestoresContent() async {
        // Given

        let client = QuoteRateClientStub()
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        } withDependencies: {
            $0[ExchangeRateClient.self].fetchLatest = {
                (base: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                // When

                try await client.fetchLatest(base)
            }
            $0[CurrencyMetadataRepository.self].fetchCodes = { [] }
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        // Then

        await store.receive(\.ratesFailed) {
            $0.isLoading = false
            $0.errorMessage = "網路連線異常，目前無法計算建議售價。"
        }
        #expect(store.state.errorMessage == "網路連線異常，目前無法計算建議售價。")
        #expect(store.state.rateUnavailableReason == "網路連線異常，目前無法計算建議售價。")

        await store.send(.rateRefreshRequested) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.ratesLoaded) {
            $0.isLoading = false
            $0.snapshot = FxRateSnapshot.fallback
            $0.errorMessage = nil
        }
        #expect(store.state.hasUsableRate)
        #expect(await client.callCount == 2)

        // 重試成功後 rateUnavailableReason 也一併恢復為 nil，不僅是 errorMessage
        #expect(store.state.rateUnavailableReason == nil)
    }

    // MARK: - Rate Unavailable Reason

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func rateUnavailableReasonIsNilWhileLoading() {
        // Given

        // 載入中由 spinner 承擔訊息，不應同時顯示「不可用原因」橫幅
        let state = QuoteFeature.State(isLoading: true)

        // When

        let rateUnavailableReason = state.rateUnavailableReason

        // Then

        #expect(rateUnavailableReason == nil)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func rateUnavailableReasonIsNilWhenRateIsUsable() {
        // Given

        let state = QuoteFeature.State(fromCurrency: .twd, snapshot: FxRateSnapshot.fallback)

        // When

        let hasUsableRate = state.hasUsableRate
        let rateUnavailableReason = state.rateUnavailableReason

        // Then

        #expect(hasUsableRate)
        #expect(rateUnavailableReason == nil)
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func rateUnavailableReasonFallsBackToGenericMessageWithoutAnErrorMessage() {
        // Given

        // 快照缺少選定幣別匯率時，無 errorMessage 也顯示通用說明
        let state = QuoteFeature.State(
            fromCurrency: .krw,
            snapshot: FxRateSnapshot(date: Date(timeIntervalSince1970: 0), base: .usd, rates: [:])
        )

        // When

        let hasUsableRate = state.hasUsableRate
        let errorMessage = state.errorMessage
        let rateUnavailableReason = state.rateUnavailableReason

        // Then

        #expect(hasUsableRate == false)
        #expect(errorMessage == nil)
        #expect(rateUnavailableReason == "尚無可用匯率資料，暫時無法試算。")
    }

    /// 驗證報價功能在此情境下的計算與狀態
    @Test func rateRefreshRequestedIsNoOpWhileAlreadyLoading() async {
        // Given

        // 重試鈕不應在載入中被誤觸發二次併發載入
        let store = TestStore(initialState: QuoteFeature.State(isLoading: true)) {
            QuoteFeature()
        }

        // When

        await store.send(.rateRefreshRequested)
        // Then

        #expect(store.state.isLoading)
    }
}

// MARK: - Test Doubles
/// 測試用的匯率 client
private actor QuoteRateClientStub {

    private(set) var callCount = 0

    /// 取得下一筆匯率快照；第一次呼叫模擬網路失敗
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
