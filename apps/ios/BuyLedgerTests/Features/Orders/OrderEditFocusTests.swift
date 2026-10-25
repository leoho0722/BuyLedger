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

/// `OrderEditFeature` 的單元測試，以 TestStore 逐步驗證表單開啟、取消與儲存時的焦點變化
struct OrderEditFocusTests {

    // MARK: - Properties

    /// 供「編輯既有訂單」情境使用的訂單
    private static let existingOrder = LedgerOrder.fixture(id: "EXISTING")

    /// 驗證開啟空白訂單時，`.task` 把焦點放到第一個欄位，即顧客名稱
    @Test
    @MainActor
    func task_開啟空白訂單_聚焦第一欄位() async {
        // Given
        let store = Self.makeStore(original: nil)

        // When
        await store.send(.view(.task)) {
            $0.focusedField = .customerName
        }

        // Then
        await store.finish()
        #expect(store.state.focusedField == .customerName)
    }

    /// 驗證開啟既有訂單時，`.task` 不設定焦點，由使用者自行決定要改哪一欄
    @Test
    @MainActor
    func task_開啟既有訂單_不搶走焦點() async {
        // Given
        let store = Self.makeStore(original: Self.existingOrder)

        // When
        await store.send(.view(.task))

        // Then
        await store.finish()
        #expect(store.state.focusedField == nil)
    }

    /// 驗證未修改的表單按下取消時，原本在顧客名稱的焦點被清除
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
        await store.send(.view(.cancelTapped)) {
            $0.focusedField = nil
        }

        // Then
        await store.finish()
        #expect(store.state.focusedField == nil)
    }

    /// 驗證顧客名稱欄位有焦點時按下儲存，焦點被清除，並送出儲存請求
    @Test
    @MainActor
    func saveTapped_欄位有焦點_清除焦點() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.customerName = "林書宇"
        initial.draft.orderSource = "IG"
        initial.draft.categories = ["美妝"]
        initial.focusedField = .customerName
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
            }
        }

        // When
        await store.send(.view(.saveTapped)) {
            $0.focusedField = nil
        }

        // Then
        await store.receive(\.delegate.saveRequested)
        await store.finish()
        #expect(store.state.focusedField == nil)
    }

    /// 驗證新建表單剛建構、尚未收到 `.task` 時，`focusedField` 為 `nil`
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

    /// 建立只驗證初始焦點、不讀取服務的編輯表單 store
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

        return TestStore(initialState: initialState) {
            OrderEditFeature()
        }
    }
}
