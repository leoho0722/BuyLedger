//
//  OrdersLoadStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證訂單清單的載入狀態與重試結果
struct OrdersLoadStateTests {

    // MARK: - Tests

    /// 已完成首次載入時，狀態解析為已載入內容
    @Test
    func loadState_訂單已載入_解析為內容狀態() {
        // Given
        var state = OrdersFeature.State()
        state.hasLoaded = true

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .loaded)
    }

    /// 已載入狀態優先於殘留的錯誤訊息
    @Test
    func loadState_已載入但殘留錯誤訊息_仍解析為內容狀態() {
        // Given
        var state = OrdersFeature.State()
        state.hasLoaded = true
        state.errorMessage = "訂單載入失敗，請稍後再試。"

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .loaded)
    }

    /// 尚未載入且有錯誤訊息時，狀態包含該失敗原因
    @Test
    func loadState_尚未載入且有錯誤_解析為失敗狀態() {
        // Given
        var state = OrdersFeature.State()
        state.errorMessage = "訂單載入失敗，請稍後再試。"

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .failed("訂單載入失敗，請稍後再試。"))
    }

    /// 尚未載入且沒有錯誤訊息時，狀態解析為載入中
    @Test
    func loadState_尚未載入且沒有錯誤_解析為載入狀態() {
        // Given
        let state = OrdersFeature.State()

        // When
        let loadState = state.loadState

        // Then
        #expect(loadState == .loading)
    }

    /// 訂單請求失敗時停止載入並顯示失敗原因
    @Test
    @MainActor
    func ordersFailed_訂單載入失敗_顯示失敗原因() async {
        // Given
        var initialState = OrdersFeature.State()
        initialState.isLoading = true
        let store = TestStore(initialState: initialState) {
            OrdersFeature()
        }

        // When
        await store.send(.ordersFailed("訂單載入失敗，請稍後再試。")) {
            $0.isLoading = false
            $0.errorMessage = "訂單載入失敗，請稍後再試。"
        }

        // Then
        #expect(store.state.loadState == .failed("訂單載入失敗，請稍後再試。"))
    }

    /// 重試成功時載入回傳訂單並清除錯誤狀態
    @Test
    @MainActor
    func task_重新載入成功_恢復訂單內容() async {
        // Given
        var initial = OrdersFeature.State()
        initial.errorMessage = "訂單載入失敗，請稍後再試。"
        let order = LedgerOrder.fixture(id: "RETRY-1")
        // 主檔全部失敗，避免載入時送出順序不固定的主檔 action
        let failingOrderSources: OrderSourceService.FetchOrderSources = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingCampaigns: CampaignService.FetchCampaigns = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingCategories: CategoryService.FetchCategories = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingPaymentMethods: PaymentMethodService.FetchPaymentMethodInfos = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingReconciliationStatuses: ReconciliationStatusService.FetchReconciliationStatuses = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderSourceService.fetchOrderSources = failingOrderSources
            $0.campaignService.fetchCampaigns = failingCampaigns
            $0.categoryService.fetchCategories = failingCategories
            $0.paymentMethodService.fetchPaymentMethodInfos = failingPaymentMethods
            $0
                .reconciliationStatusService
                .fetchReconciliationStatuses = failingReconciliationStatuses
            $0.orderService.fetchOrders = {
                [order]
            }
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        // Then
        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = [order]
            $0.selectedOrderID = order.id
        }
        #expect(store.state.orders == [order])
        #expect(store.state.selectedOrderID == order.id)
        #expect(store.state.loadState == .loaded)
    }

    /// 已在失敗狀態時再收到相同失敗，保留錯誤且不自動重試
    ///
    /// - Note: 窮舉的 `TestStore` 會在未處理自動重試 action 時使測試失敗
    @Test
    @MainActor
    func ordersFailed_重複載入失敗_維持失敗狀態() async {
        // Given
        var initialState = OrdersFeature.State()
        initialState.errorMessage = "訂單載入失敗，請稍後再試。"
        let store = TestStore(initialState: initialState) {
            OrdersFeature()
        }

        // When
        await store.send(.ordersFailed("訂單載入失敗，請稍後再試。"))

        // Then
        #expect(store.state.loadState == .failed("訂單載入失敗，請稍後再試。"))
        #expect(store.state.hasLoaded == false)
    }
}
