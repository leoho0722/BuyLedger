//
//  DashboardFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 驗證總覽功能
@MainActor
struct DashboardFeatureTests {
    
    // MARK: - Tests
    
    /// 驗證畫面出現時轉發 refresh
    @Test func taskEmitsRefreshDelegate() async {
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }
        
        await store.send(.task)
        await store.receive(\.delegate.refresh)
    }
    
    /// 載入失敗畫面的重試鈕與 `.task` 送出同一個 delegate，不自帶額外守衛
    @Test func retryTappedEmitsRefreshDelegate() async {
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }
        
        await store.send(.retryTapped)
        await store.receive(\.delegate.refresh)
    }
    
    /// 驗證開團卡點選轉發 delegate
    @Test func campaignTappedDelegateMutatesNoState() async {
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }
        
        await store.send(.delegate(.campaignTapped("四月韓國團")))
    }
    
    /// 「建立第一筆訂單」只送出 delegate，理由同上
    @Test func newOrderTappedDelegateMutatesNoState() async {
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }
        
        await store.send(.delegate(.newOrderTapped))
    }
    
    /// 「查看全部」只送出 delegate，理由同上
    @Test func viewAllOrdersTappedDelegateMutatesNoState() async {
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        }
        
        await store.send(.delegate(.viewAllOrdersTapped))
    }
}
