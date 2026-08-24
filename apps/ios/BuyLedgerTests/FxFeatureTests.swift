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

@MainActor
/// 驗證匯率工具的狀態更新與計算
struct FxFeatureTests {
    
    // MARK: - Tests
    
    @Test func defaultStateUsesKrwAt150K() {
        let state = FxFeature.State()
        
        #expect(state.fromCurrency == .krw)
        #expect(state.amount == 150_000)
    }
    
    @Test func defaultStateHasNoSnapshotAndNilRate() {
        let state = FxFeature.State()
        
        #expect(state.snapshot == nil)
        #expect(state.rate == nil)
        #expect(state.convertedTwd == nil)
    }
    
    @Test func switchingCurrencyRecomputesRateFromSnapshot() async {
        // 切換幣別後使用 snapshot 匯率，不使用 fallback
        let store = TestStore(
            initialState: FxFeature.State(snapshot: FxRateSnapshot.fallback)
        ) {
            FxFeature()
        }
        
        await store.send(\.binding.fromCurrency, .jpy) {
            $0.fromCurrency = .jpy
        }
        
        let expectedRate = FxRateSnapshot.fallback.rates[.jpy].map { Decimal(1) / $0 }
        #expect(store.state.rate == expectedRate)
        #expect(store.state.convertedTwd == expectedRate.map { 150_000 * $0 })
    }
    
    @Test func quickAmountTappedReplacesAmount() async {
        let store = TestStore(initialState: FxFeature.State()) {
            FxFeature()
        }
        
        await store.send(.quickAmountTapped(50_000)) {
            $0.amount = 50_000
        }
    }
    
    @Test func bindingAmountUpdatesConvertedTwd() async {
        let store = TestStore(
            initialState: FxFeature.State(snapshot: FxRateSnapshot.fallback)
        ) {
            FxFeature()
        }
        
        await store.send(\.binding.amount, 100_000) {
            $0.amount = 100_000
        }
        
        let expectedRate = FxRateSnapshot.fallback.rates[.krw].map { Decimal(1) / $0 }
        #expect(store.state.convertedTwd == expectedRate.map { 100_000 * $0 })
    }
    
    @Test func displayRateForTwdAlwaysReturnsOneEvenWithoutSnapshot() {
        let state = FxFeature.State()
        
        #expect(state.displayRate(for: .twd) == 1)
    }
    
    @Test func bindingTogglesCurrencySheet() async {
        // 幣別選擇 sheet 開關已下放 State，走 binding 管理
        let store = TestStore(initialState: FxFeature.State()) {
            FxFeature()
        }
        
        await store.send(\.binding.showsCurrencySheet, true) {
            $0.showsCurrencySheet = true
        }
    }
    
    @Test func currencyPickerTappedShowsCurrencySheet() async {
        let store = TestStore(initialState: FxFeature.State()) {
            FxFeature()
        }
        
        await store.send(.currencyPickerTapped) {
            $0.showsCurrencySheet = true
        }
    }
    
    @Test func fromCurrencySelectedRecomputesRateFromSnapshot() async {
        // 由 action 更新幣別後，匯率與換算金額仍取自 snapshot
        let store = TestStore(
            initialState: FxFeature.State(snapshot: FxRateSnapshot.fallback)
        ) {
            FxFeature()
        }
        
        await store.send(.fromCurrencySelected("JPY")) {
            $0.fromCurrency = .jpy
        }
        
        let expectedRate = FxRateSnapshot.fallback.rates[.jpy].map { Decimal(1) / $0 }
        #expect(store.state.rate == expectedRate)
        #expect(store.state.convertedTwd == expectedRate.map { 150_000 * $0 })
    }
}
