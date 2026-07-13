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

        // snapshot 使用 base = .twd，rates[.krw] = 1 / 0.0228 ≈ 43.86 KRW per TWD
        // 所以 1 KRW = 0.0228 TWD，100,000 × 0.0228 = 2280 TWD
        // 注意：Double 乘法會帶 1e-12 級的浮點誤差，需以 tolerance 比較
        #expect(abs(state.itemTwd - 2_280) < 0.0001)
        #expect(abs(state.costTwd - 2_280) < 0.0001)
    }

    @Test func costCalculationIsZeroWithoutSnapshot() {
        // 沒有 snapshot 時 rate = 0、所有衍生金額一併歸零，view 應顯示「尚無可用匯率資料」橫幅
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
        // 國際運費是 TWD 計，理論上會留下；但 itemTwd / domesticTwd / cardFeeTwd 全部歸零
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

        // cost 100, suggested raw = 125, rounds up to 130
        #expect(state.costTwd == 100)
        #expect(state.suggestedTwd == 130)
        #expect(state.estimatedProfitTwd == 30)
    }

    @Test func switchingCurrencyRecomputesItemTwd() async {
        // 預設 itemPrice 為 0，這裡顯式注入一個非零值才能驗證匯率切換對 itemTwd 的影響
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

        // 1000 × 1.10 = 1100 → already on 10
        #expect(store.state.suggestedTwd == 1_100)

        await store.send(\.binding.targetMarginPercent, 50) {
            $0.targetMarginPercent = 50
        }

        // 1000 × 1.50 = 1500 → already on 10
        #expect(store.state.suggestedTwd == 1_500)
    }

    @Test func negativeInputsClampToZeroOnBinding() async {
        // 非負驗證下放 reducer：任何寫入負值的數值欄 binding 都在 Store 被 clamp 成 0，唯一把關點在 reducer
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
        // 幣別選擇 sheet 的顯示狀態改由 State 管理，binding 寫入後不受非負 clamp 影響
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
        // 幣別選擇 sheet 選定幣別 → reducer 建構 CurrencyCode 並寫入 state，itemTwd 等衍生金額隨之連動重算
        let store = TestStore(initialState: QuoteFeature.State(itemPrice: 150_000)) {
            QuoteFeature()
        }

        await store.send(.fromCurrencySelected("TWD")) {
            $0.fromCurrency = .twd
        }

        // TWD rate = 1, so itemTwd == itemPrice
        #expect(store.state.itemTwd == 150_000)
    }
}
