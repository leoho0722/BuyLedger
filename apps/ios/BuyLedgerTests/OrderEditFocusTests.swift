//
//  OrderEditFocusTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證訂單編輯表單的焦點管理
struct OrderEditFocusTests {

    // MARK: - Properties

    /// 供「編輯既有訂單」情境使用的訂單
    private static let existingOrder = LedgerOrder.fixture(id: "EXISTING")

    // MARK: - Tests

    /// 開啟空白訂單時將焦點放在第一個欄位
    @Test
    @MainActor
    func task_開啟空白訂單_聚焦第一欄位() async {
        // Given
        let store = Self.makeStore(original: nil)

        // When
        await store.send(.task) {
            $0.focusedField = .customerName
        }

        // Then
        await store.finish()
        #expect(store.state.focusedField == .customerName)
    }

    /// 編輯既有訂單不搶焦點，讓使用者自行決定要改哪一欄
    @Test
    @MainActor
    func task_開啟既有訂單_不搶走焦點() async {
        // Given
        let store = Self.makeStore(original: Self.existingOrder)

        // When
        await store.send(.task) {
            $0.photoLoadPhase = .loading
        }

        // Then
        await store.receive(\.photosLoaded) {
            $0.photoLoadPhase = .loaded
        }
        await store.finish()
        #expect(store.state.focusedField == nil)
    }

    /// 未修改的表單按下取消時，清除目前已取得的輸入焦點
    @Test
    @MainActor
    func cancelTapped_表單未修改_清除焦點() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.focusedField = .customerName
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.cancelTapped) {
            $0.focusedField = nil
        }

        // Then
        await store.finish()
        #expect(store.state.focusedField == nil)
    }

    /// 儲存表單時清除目前已取得的輸入焦點
    @Test
    @MainActor
    func saveTapped_欄位有焦點_清除焦點() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.focusedField = .customerName
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.saveTapped) {
            $0.focusedField = nil
        }

        // Then
        await store.finish()
        #expect(store.state.focusedField == nil)
    }

    /// 建立新訂單的初始表單沒有焦點
    ///
    /// - Note: 父層關閉後重新開啟表單的焦點行為由父層測試負責
    @Test
    func init_新建表單初始狀態_沒有焦點() {
        // Given
        let id = UUID(0)
        let currentDate = TestDependencies.fixedNow

        // When
        let state = OrderEditFeature.State(id: id, currentDate: currentDate)

        // Then
        #expect(state.focusedField == nil)
    }
}

// MARK: - Private Method

private extension OrderEditFocusTests {

    /// 建立覆寫失敗主檔服務的編輯表單 store
    ///
    /// - Parameter original: 要編輯的原始訂單；新增訂單時為 `nil`
    /// - Returns: 已建立的 `OrderEditFeature` 測試 store
    @MainActor
    static func makeStore(original: LedgerOrder?) -> TestStoreOf<OrderEditFeature> {
        let initialState = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        let failingOrderSources: OrderSourceService.FetchOrderSources = {
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
        let failingCampaigns: CampaignService.FetchCampaigns = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }

        return TestStore(initialState: initialState) {
            OrderEditFeature()
        } withDependencies: {
            $0.currencyMetadataService.fetchCodes = {
                []
            }
            if original != nil {
                $0.orderService.fetchOrderPhotos = { _ in
                    []
                }
            }
            $0.orderSourceService.fetchOrderSources = failingOrderSources
            $0.categoryService.fetchCategories = failingCategories
            $0.paymentMethodService.fetchPaymentMethodInfos = failingPaymentMethods
            $0
                .reconciliationStatusService
                .fetchReconciliationStatuses = failingReconciliationStatuses
            $0.campaignService.fetchCampaigns = failingCampaigns
        }
    }
}
