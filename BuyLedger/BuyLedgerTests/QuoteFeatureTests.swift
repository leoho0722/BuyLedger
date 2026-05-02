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

    @Test func defaultStateMatchesDesignPreset() {
        let state = QuoteFeature.State()

        #expect(state.fromCurrency == .krw)
        #expect(state.itemPrice == 150_000)
        #expect(state.domesticShipping == 3_000)
        #expect(state.internationalShippingTwd == 180)
        #expect(state.cardFeePercent == 2.5)
        #expect(state.targetMarginPercent == 25)
    }

    @Test func costCalculationUsesRateAndCardFee() {
        // 注入 fallback snapshot 模擬 API 已回應；runtime 已不再使用 hardcoded fallback。
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
        // 注意：Double 乘法會帶 1e-12 級的浮點誤差，需以 tolerance 比較。
        #expect(abs(state.itemTwd - 2_280) < 0.0001)
        #expect(abs(state.costTwd - 2_280) < 0.0001)
    }

    @Test func costCalculationIsZeroWithoutSnapshot() {
        // 沒有 snapshot 時 rate = 0、所有衍生金額一併歸零，view 應顯示「尚無可用匯率資料」橫幅。
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
        // 國際集運是 TWD 計，理論上會留下；但 itemTwd / domesticTwd / cardFeeTwd 全部歸零
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
        let store = TestStore(initialState: QuoteFeature.State()) {
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
}
