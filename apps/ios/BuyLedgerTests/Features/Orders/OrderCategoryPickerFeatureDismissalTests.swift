//
//  OrderCategoryPickerFeatureDismissalTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderCategoryPickerFeature` 的單元測試，以 TestStore 逐步驗證取消與捨棄確認時送出的通知與狀態還原
@MainActor
struct OrderCategoryPickerFeatureDismissalTests {

    /// 驗證只變更搜尋文字、焦點與展開等呈現狀態時，按下取消不詢問捨棄，直接送出取消通知
    @Test
    func cancelTapped_只改搜尋焦點與展開_直接委派取消() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState(committed: ["beauty"])
        state.searchText = "boo"
        state.isSearchFieldFocused = true
        state.groupExpansion.expandedKinds = [.closed]
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.cancelTapped))

        // Then
        await store.receive(\.delegate.cancelled)
        #expect(store.state.discardConfirmation == nil)
        #expect(store.state.pendingCategories == ["beauty"])
    }

    /// 驗證暫存新增了書籍時按下取消，先跳出捨棄確認，暫存與已套用的類別都保留不變
    @Test
    func cancelTapped_暫存新增書籍_先詢問捨棄且保留集合() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState(committed: ["beauty"])
        state.pendingCategories = ["beauty", "books"]
        let confirmation = OrderCategoryPickerFeatureTestSupport.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.cancelTapped)) {
            $0.discardConfirmation = confirmation
        }

        // Then
        #expect(store.state.pendingCategories == ["beauty", "books"])
        #expect(store.state.committedCategories == ["beauty"])
        #expect(store.state.discardConfirmation == confirmation)
    }

    /// 驗證暫存只是換成另一個類別、筆數相同時，按下取消仍先跳出捨棄確認，不會只比數量就靜默捨棄
    @Test
    func cancelTapped_暫存改為另一類別_先詢問捨棄且保留集合() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState(committed: ["beauty"])
        state.pendingCategories = ["books"]
        let confirmation = OrderCategoryPickerFeatureTestSupport.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.cancelTapped)) {
            $0.discardConfirmation = confirmation
        }

        // Then
        #expect(store.state.pendingCategories == ["books"])
        #expect(store.state.committedCategories == ["beauty"])
        #expect(store.state.hasUnappliedChanges == true)
    }

    /// 驗證在捨棄確認中選擇捨棄時，暫存還原為已套用的類別，並送出取消通知
    @Test
    func discardConfirmation_確認捨棄變更_還原集合並委派取消() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState(committed: ["beauty"])
        state.pendingCategories = ["beauty", "books"]
        state.discardConfirmation = OrderCategoryPickerFeatureTestSupport.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.discardConfirmation(.presented(.discard))) {
            $0.discardConfirmation = nil
            $0.pendingCategories = ["beauty"]
        }

        // Then
        await store.receive(\.delegate.cancelled)
        #expect(store.state.committedCategories == ["beauty"])
        #expect(store.state.hasUnappliedChanges == false)
    }

    /// 驗證在捨棄確認中選擇繼續編輯時，確認關閉、暫存保留，且不送出取消通知
    @Test
    func discardConfirmation_繼續編輯_保留暫存且不提交() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState(committed: ["beauty"])
        state.pendingCategories = ["beauty", "books"]
        state.discardConfirmation = OrderCategoryPickerFeatureTestSupport.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.discardConfirmation(.dismiss)) {
            $0.discardConfirmation = nil
        }

        // Then
        #expect(store.state.pendingCategories == ["beauty", "books"])
        #expect(store.state.committedCategories == ["beauty"])
    }

    /// 驗證暫存已回到與已套用相同的集合時，按下取消不詢問，直接送出取消通知，且不送出套用通知
    @Test
    func cancelTapped_暫存已回到原集合_直接委派取消() async {
        // Given
        let store = TestStore(
            initialState: OrderCategoryPickerFeatureTestSupport.makeState(committed: ["snacks"])
        ) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.cancelTapped))

        // Then
        await store.receive(\.delegate.cancelled)
        #expect(store.state.discardConfirmation == nil)
        #expect(store.state.pendingCategories == ["snacks"])
    }
}
