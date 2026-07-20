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
///
/// 總覽頁與分析頁共用 ``OrdersFeature/State/loadState``，此處鎖住其解析順序，
/// 確保載入失敗不會被誤判成載入中
@MainActor
struct OrdersLoadStateTests {

    // MARK: - Tests

    // MARK: 狀態解析

    @Test func loadedStateResolvesToContent() {
        var state = OrdersFeature.State()
        state.hasLoaded = true

        #expect(state.loadState == .loaded)
    }

    /// 已載入後即使殘留錯誤訊息也維持顯示內容，對齊 spec 的解析順序表
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
        }
        store.exhaustivity = .off

        // 重試沿用既有的載入動作，不新增狀態欄位；`.task` 的守衛在失敗後不會擋下重試
        await store.send(.task)
        await store.send(.ordersLoaded([]))

        #expect(store.state.loadState == .loaded)
    }

    /// 重試再次失敗時維持失敗狀態，且不清空錯誤訊息、不進入自動重試迴圈
    @Test func repeatedFailureKeepsTheFailureStateWithoutLooping() async {
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        }
        store.exhaustivity = .off

        await store.send(.ordersFailed("訂單載入失敗，請稍後再試。"))
        await store.send(.ordersFailed("訂單載入失敗，請稍後再試。"))

        #expect(store.state.loadState == .failed("訂單載入失敗，請稍後再試。"))
        #expect(store.state.hasLoaded == false)
    }
}
