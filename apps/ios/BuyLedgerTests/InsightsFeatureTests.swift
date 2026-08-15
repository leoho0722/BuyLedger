//
//  InsightsFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 驗證分析功能
@MainActor
struct InsightsFeatureTests {
    
    // MARK: - Tests
    
    /// 分析區間切換後會保留在 feature state
    @Test func insightsDateRangeBindingPersistsSelection() async {
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }
        
        await store.send(\.binding.insightsDateRange, .thirtyDays) {
            $0.insightsDateRange = .thirtyDays
        }
        
        #expect(store.state.insightsDateRange == .thirtyDays)
    }
    
    /// 驗證畫面出現時轉發 refresh
    @Test func taskEmitsRefreshDelegate() async {
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }
        
        await store.send(.task)
        await store.receive(\.delegate.refresh)
    }
    
    /// 驗證毛利排行點選轉發 delegate
    @Test func campaignTappedDelegateMutatesNoState() async {
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }
        
        await store.send(.delegate(.campaignTapped("四月韓國團")))
    }
    
    /// 類別排行點選只送出 delegate，理由同上
    @Test func categoryTappedDelegateMutatesNoState() async {
        let store = TestStore(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }
        
        await store.send(.delegate(.categoryTapped("美妝")))
    }
}
