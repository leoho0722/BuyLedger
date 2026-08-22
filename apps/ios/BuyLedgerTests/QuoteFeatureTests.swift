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

@MainActor
/// 驗證報價試算流程
struct QuoteFeatureTests {
    
    // MARK: - Tests
    
    @Test func defaultStateStartsAtZero() {
        // 預設值全為 0：頁面剛開時不預填示範金額或費率
        // 避免讓使用者誤以為畫面上的「建議售價」是已存在的試算結果
        let state = QuoteFeature.State()
        
        #expect(state.fromCurrency == .krw)
        #expect(state.itemPrice == 0)
        #expect(state.domesticShipping == 0)
        #expect(state.internationalShippingTwd == 0)
        #expect(state.cardFeePercent == 0)
        #expect(state.targetMarginPercent == 0)
    }
    
    @Test func costCalculationUsesRateAndCardFee() {
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
        #expect(abs(state.itemTwd - 2_280) < tolerance)
        #expect(abs(state.costTwd - 2_280) < tolerance)
    }
    
    @Test func costCalculationIsZeroWithoutSnapshot() {
        // 沒有匯率資料時，衍生金額歸零並顯示提示。
        let state = QuoteFeature.State(
            fromCurrency: .krw,
            itemPrice: 100_000,
            domesticShipping: 5_000,
            internationalShippingTwd: 180,
            cardFeePercent: 2.5,
            targetMarginPercent: 25
        )
        
        #expect(state.snapshot == nil)
        #expect(state.hasUsableRate == false)
        // 國際運費以 TWD 計算，其他項目因匯率不可用而為零。
        #expect(state.itemTwd == 0)
        #expect(state.domesticTwd == 0)
        #expect(state.cardFeeTwd == 0)
        // costTwd = 0 + 0 + 180 + 0 = 180
        #expect(state.costTwd == 180)
    }
    
    @Test func suggestedPriceRoundsUpToNearestTen() {
        let state = QuoteFeature.State(
            fromCurrency: .twd,
            itemPrice: 100,
            domesticShipping: 0,
            internationalShippingTwd: 0,
            cardFeePercent: 0,
            targetMarginPercent: 25
        )
        
        // 真毛利 1000 / 0.75 = 133.33，無條件進位到 140
        #expect(state.costTwd == 100)
        #expect(state.suggestedTwd == 140)
        #expect(state.estimatedProfitTwd == 40)
    }
    
    @Test func switchingCurrencyRecomputesItemTwd() async {
        // 使用非零單價驗證匯率切換對 itemTwd 的影響。
        let store = TestStore(initialState: QuoteFeature.State(itemPrice: 150_000)) {
            QuoteFeature()
        }
        
        await store.send(\.binding.fromCurrency, .twd) {
            $0.fromCurrency = .twd
        }
        
        // TWD rate = 1, so itemTwd == itemPrice
        #expect(store.state.itemTwd == 150_000)
    }
    
    @Test func bindingMarginUpdatesSuggestedPrice() async {
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
        #expect(store.state.suggestedTwd == 1_120)
        
        await store.send(\.binding.targetMarginPercent, 50) {
            $0.targetMarginPercent = 50
        }
        
        // cost / (1 − 0.50) = 2000，本身即十元整數
        #expect(store.state.suggestedTwd == 2_000)
    }
    
    @Test func negativeInputsClampToZeroOnBinding() async {
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
    }
    
    @Test func bindingTogglesCurrencySheet() async {
        // 幣別 sheet 狀態由 State 管理，binding 不受 clamp 影響。
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        }
        
        await store.send(\.binding.showsCurrencySheet, true) {
            $0.showsCurrencySheet = true
        }
    }
    
    @Test func currencyPickerTappedShowsSheet() async {
        // 點擊來源幣別列 → reducer 開啟幣別選擇 sheet，View 不再直接寫入 store
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        }
        
        await store.send(.currencyPickerTapped) {
            $0.showsCurrencySheet = true
        }
    }
    
    @Test func fromCurrencySelectedUpdatesCurrencyAndRecomputesItemTwd() async {
        // 選幣別後重算衍生金額
        let store = TestStore(initialState: QuoteFeature.State(itemPrice: 150_000)) {
            QuoteFeature()
        }
        
        await store.send(.fromCurrencySelected("TWD")) {
            $0.fromCurrency = .twd
        }
        
        // TWD rate = 1, so itemTwd == itemPrice
        #expect(store.state.itemTwd == 150_000)
    }
    
    // MARK: - Gross Margin Formula
    
    @Test func suggestedPriceMatchesGrossMarginFormulaExamples() throws(any Error) {
        // 50% 目標毛利應得到 2 倍成本，區分毛利率與加成率公式。
        let zero = QuoteFeature.State(fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 0)
        #expect(zero.suggestedTwd == 1_000)
        #expect(zero.estimatedMarginPercent == 0)
        
        // 成本 1000、目標毛利 30% 時，建議售價應為 1430
        let thirty = QuoteFeature.State(
            fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 30)
        #expect(thirty.suggestedTwd == 1_430)
        let thirtyMargin = try #require(thirty.estimatedMarginPercent)
        // 容許因售價捨入造成的些微落差 (捨入前的精確毛利率就是 30%)
        #expect(abs(thirtyMargin - 30) < 1)
        
        let fifty = QuoteFeature.State(
            fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 50)
        #expect(fifty.suggestedTwd == 2_000)
        #expect(fifty.estimatedMarginPercent == 50)
    }
    
    @Test func targetMarginAtOrAboveOneHundredPercentYieldsNoPrice() async {
        // 100% 以上無法計算，三個結果都應隱藏，輸入值不夾住。
        let store = TestStore(
            initialState: QuoteFeature.State(
                fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 50)
        ) {
            QuoteFeature()
        }
        
        // 低於 100%：三個數字皆有值
        #expect(store.state.isTargetMarginBelowOneHundredPercent == true)
        #expect(store.state.suggestedTwd != nil)
        #expect(store.state.estimatedProfitTwd != nil)
        #expect(store.state.estimatedMarginPercent != nil)
        
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
    
    @Test func decimalTypeAvoidsBinaryFloatingPointDrift() {
        // Decimal 應精確得到 0.3，避免 Double 的二進位誤差。
        let state = QuoteFeature.State(
            fromCurrency: .twd,
            itemPrice: Decimal(string: "0.1")!,
            domesticShipping: Decimal(string: "0.2")!
        )
        
        #expect(state.itemTwd + state.domesticTwd == Decimal(string: "0.3")!)
    }
    
    @Test func quoteCostAgreesWithOrderTotalCostForMatchingInputs() {
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
        
        #expect(quote.costTwd == OrderSummary(order: order).totalCost)
    }
    
    @Test func failedRateLoadExplainsReasonAndRetryRestoresContent() async {
        let client = QuoteRateClientStub()
        let store = TestStore(initialState: QuoteFeature.State()) {
            QuoteFeature()
        } withDependencies: {
            $0[ExchangeRateClient.self].fetchLatest = { (base: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                try await client.fetchLatest(base)
            }
            $0[CurrencyMetadataRepository.self].fetchCodes = { [] }
        }
        
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
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
    
    @Test func rateUnavailableReasonIsNilWhileLoading() {
        // 載入中由 spinner 承擔訊息，不應同時顯示「不可用原因」橫幅
        let state = QuoteFeature.State(isLoading: true)
        
        #expect(state.rateUnavailableReason == nil)
    }
    
    @Test func rateUnavailableReasonIsNilWhenRateIsUsable() {
        let state = QuoteFeature.State(fromCurrency: .twd, snapshot: FxRateSnapshot.fallback)
        
        #expect(state.hasUsableRate)
        #expect(state.rateUnavailableReason == nil)
    }
    
    @Test func rateUnavailableReasonFallsBackToGenericMessageWithoutAnErrorMessage() {
        // 快照缺少選定幣別匯率時，無 errorMessage 也顯示通用說明
        let state = QuoteFeature.State(
            fromCurrency: .krw,
            snapshot: FxRateSnapshot(date: Date(timeIntervalSince1970: 0), base: .usd, rates: [:])
        )
        
        #expect(state.hasUsableRate == false)
        #expect(state.errorMessage == nil)
        #expect(state.rateUnavailableReason == "尚無可用匯率資料，暫時無法試算。")
    }
    
    @Test func rateRefreshRequestedIsNoOpWhileAlreadyLoading() async {
        // 重試鈕不應在載入中被誤觸發二次併發載入
        let store = TestStore(initialState: QuoteFeature.State(isLoading: true)) {
            QuoteFeature()
        }
        
        await store.send(.rateRefreshRequested)
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
            throw APIError.transport(message: "network unavailable")
        }
        return FxRateSnapshot.fallback
    }
}
