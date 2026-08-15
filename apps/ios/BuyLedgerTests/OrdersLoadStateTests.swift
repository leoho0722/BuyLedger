//
//  OrdersLoadStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Testing
@testable import BuyLedger

/// 訂單載入的三種狀態解析
@MainActor
struct OrdersLoadStateTests {
    
    // MARK: - Tests
    
    // MARK: 狀態解析
    
    @Test func loadedStateResolvesToContent() {
        var state = OrdersFeature.State()
        state.hasLoaded = true
        
        #expect(state.loadState == .loaded)
    }
    
    /// 驗證已載入狀態優先於錯誤訊息
    @Test func loadedStateWinsOverALingeringErrorMessage() {
        var state = OrdersFeature.State()
        state.hasLoaded = true
        state.errorMessage = "訂單載入失敗，請稍後再試。"
        
        #expect(state.loadState == .loaded)
    }
    
    @Test func errorWithoutLoadResolvesToFailure() {
        var state = OrdersFeature.State()
        state.errorMessage = "訂單載入失敗，請稍後再試。"
        
        #expect(state.loadState == .failed("訂單載入失敗，請稍後再試。"))
    }
    
    @Test func neitherLoadedNorFailedResolvesToLoading() {
        let state = OrdersFeature.State()
        
        #expect(state.loadState == .loading)
    }
    
    // MARK: 失敗與重試
    
    @Test func failedLoadSurfacesTheReasonInsteadOfSpinningForever() async {
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        }
        
        await store.send(.ordersFailed("訂單載入失敗，請稍後再試。")) {
            $0.isLoading = false
            $0.errorMessage = "訂單載入失敗，請稍後再試。"
        }
        
        #expect(store.state.loadState == .failed("訂單載入失敗，請稍後再試。"))
    }
    
    @Test func retryAfterFailureRestoresNormalContent() async {
        var initial = OrdersFeature.State()
        initial.errorMessage = "訂單載入失敗，請稍後再試。"
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            // 只測重試，讓主檔載入明確失敗。
            $0[OrderSourceRepository.self].fetchOrderSources = {
                () async throws(PersistenceError) -> [String] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
            $0[CampaignRepository.self].fetchCampaigns = {
                () async throws(PersistenceError) -> [Campaign] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
            $0[CategoryRepository.self].fetchCategories = {
                () async throws(PersistenceError) -> [String] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
            $0[PaymentMethodRepository.self].fetchPaymentMethodInfos = {
                () async throws(PersistenceError) -> [PaymentMethodInfo] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
            $0[ReconciliationStatusRepository.self].fetchReconciliationStatuses = {
                () async throws(PersistenceError) -> [String] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
            // 讓 `.task` 真正呼叫 fetchOrders 並回傳空陣列。
            $0[OrderRepository.self].fetchOrders = { [] }
        }
        
        // 重試沿用既有載入動作。
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = []
            $0.selectedOrderID = nil
        }
        
        #expect(store.state.loadState == .loaded)
    }
    
    /// 重試再次失敗時維持失敗狀態，且不清空錯誤訊息、不進入自動重試迴圈
    @Test func repeatedFailureKeepsTheFailureStateWithoutLooping() async {
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        }
        
        await store.send(.ordersFailed("訂單載入失敗，請稍後再試。")) {
            $0.isLoading = false
            $0.errorMessage = "訂單載入失敗，請稍後再試。"
        }
        // 重複失敗時狀態不變。
        // 這正是本測試要鎖住的「不進入自動重試迴圈」行為
        await store.send(.ordersFailed("訂單載入失敗，請稍後再試。"))
        
        #expect(store.state.loadState == .failed("訂單載入失敗，請稍後再試。"))
        #expect(store.state.hasLoaded == false)
    }
}
